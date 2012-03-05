#!/usr/bin/perl -w

use strict;
use DBI;

#print "$$ $^O $ 0 $^T $^X\n";
#$disk[0] = [0, "/dev/sda2", 150000000000, 0];
my $dirseparator = "/";
my $disksize = 4690000000;
my $label = "Muzix";
my $diskroot = "/mnt/cdrom";
my $treeroot = "/home/hamu/Muzikz";
my $percent = 0;
my $dbh = DBI->connect("dbi:SQLite:teszt.db",{RaiseError => 1, AutoCommit => 1}) || die "Cannot connect: $DBI::errstr";
my $x;
my @prep;

my @queries = (
'SELECT * FROM disk ORDER BY id',					# 0.
q{SELECT size, url, id
	FROM file, filedir, filedisk
	WHERE size<?
	AND id=filedir.fileid
	AND dirid=0
	AND id=filedisk.fileid
	AND diskid=0
UNION
SELECT f1.size, url, f1.id
	FROM file AS f1, file AS f2, filedir AS d1, filedir AS d2, filedisk
	WHERE f2.size>=?
	AND f2.id=d1.dirid
	AND d1.dirid=d2.fileid
	AND d2.dirid=0
	AND f1.id=d1.fileid
	AND f1.id=filedisk.fileid
	AND diskid=0
EXCEPT
SELECT size, fd1.url, id
	FROM file, filedisk AS fd1, filedisk AS fd2
	WHERE fd1.diskid=0
	AND fd1.fileid=id
	AND fd2.fileid=fd1.fileid
	AND fd2.diskid<>0
ORDER BY size DESC},							# 1.
'INSERT INTO disk (name, size, percent) VALUES(?,?,?)',		# 2.
'INSERT INTO filedisk (fileid, url, diskid) VALUES (?,?,?)',		# 3.
'SELECT * FROM disk WHERE name=? AND size=?',				# 4.
q{SELECT f1.id, f2.id, f1.name, f1.size 
	FROM file AS f1, file AS f2
	WHERE f1.id<f2.id
	AND f1.size=f2.size
	AND f1.name=f2.name
ORDER BY f1.size DESC});						# 5.

for $x (@queries){$prep[@prep] = $dbh->prepare_cached($x);}

my $success = 1;

my @tmprow;
my @dirlist;
my $sum = 0;

$prep[1]->execute($disksize, $disksize);

while(@tmprow = $prep[1]->fetchrow_array()){
	if($tmprow[0] + $sum < $disksize){
		$dirlist[@dirlist] = [$tmprow[0], $tmprow[1], $tmprow[2]];
		$sum += $tmprow[0];
		print "$sum $dirlist[@dirlist-1][0] $dirlist[@dirlist-1][1] $dirlist[@dirlist-1][2]\n";
	}
}
$percent = $sum / $disksize * 100;
print "$percent %\n\n";

if($percent>0){
	$prep[0]->execute();
	
	for($x = 0; $prep[0]->fetchrow_arrayref(); $x++){}

	$label = $label . $x;

	print "$label\n";	

	$prep[2]->execute($label, $disksize, $percent);
	$prep[0]->execute();
	
	while((@tmprow = $prep[0]->fetchrow_array()) && ($tmprow[1] ne $label || $tmprow[2] != $disksize)){}
	
	print "@tmprow\n";
	
	for $x (@dirlist){
		$x->[1] =~ s/$treeroot/$diskroot/;
		$prep[3]->execute($x->[2], $x->[1], $tmprow[0]);
		print $x->[2] . ", " . $x->[1] . ", " . $tmprow[0] . "\n";
	}
#	$dbh->commit();

	$sum = `dcop k3b K3bInterface createDataDVDProject`; 
	$sum =~ s/\n//;
	print "\n$sum\n\n";
	
	for $x (@dirlist){
		$x->[1] =~ s/$diskroot/$treeroot/;
		system("dcop", $sum, "addUrl(KURL)", $x->[1]);
	}
	system("dcop", $sum, "addUrl(KURL)", "/home/hamu/src/bakup/teszt.db");
}
