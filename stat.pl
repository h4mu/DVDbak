#!/usr/bin/perl -w

use strict;
use DBI;

#print "$$ $^O $ 0 $^T $^X\n";
my $lastparent = 0;
my @disk = (0, "/dev/sda2", 150000000000, 0);
my $dirseparator = "/";
my @dirlist;
$dirlist[$lastparent] = "/home/hamu/Muzikz";
my @diridlist;
$diridlist[$lastparent] = 0;
my $fileid = 0;
$dirlist[$lastparent] =~ /\/([^\/]*)$/;
my $x = $1;
my $y = $dirlist[$lastparent];
my @files;
$files[0] = [-1, $x, "TRUE", (stat($y))[7]];
my @filedir;
my @filedisk;

my $dbh = DBI->connect("dbi:SQLite:teszt.db",{RaiseError => 1, AutoCommit => 0}) || die "Cannot connect: $DBI::errstr";

my $fins = $dbh->prepare_cached('INSERT OR IGNORE INTO file (id, name, dir, size) VALUES (?,?,?,?)'); 
my $fdirins = $dbh->prepare_cached('INSERT OR IGNORE INTO filedir (fileid, dirid) VALUES (?,?)'); 
my $fdskins = $dbh->prepare_cached('INSERT OR IGNORE INTO filedisk (fileid, url, diskid) VALUES (?,?,?)'); 
my $dskins = $dbh->prepare_cached('INSERT OR IGNORE INTO disk (id, name, size, percent) VALUES(?,?,?,?)'); 
die "Couldn't prepare queries; aborting"
            unless defined $fins && defined $fdirins && defined $fdskins && defined $dskins;
my $success = 1;

print "$files[$fileid][0] $files[$fileid][1] $files[$fileid][2] $files[$fileid][3]\n";

#files
for(; $lastparent < @dirlist; $lastparent++){
	opendir(DIR, $dirlist[$lastparent]) or die "opendir";
	my @dircontents = readdir(DIR);
	closedir(DIR);
	for $x (@dircontents){
		$y = $dirlist[$lastparent].$dirseparator.$x;
		if(( -d $y || -f $y) && $x ne "." && $x ne ".."){ #-d $y || -f $y
			$fileid++;
			if(-d $y){
				$files[$fileid] = [$fileid, $x, "TRUE", (stat($y))[7]];
				$dirlist[@dirlist] = $y;
				$diridlist[@dirlist-1] = $fileid;
			}elsif(-f $y){
				$files[$fileid] = [$fileid, $x, "FALSE", (stat($y))[7]];
			}
			$filedir[$fileid] = [$fileid, $diridlist[$lastparent]];
			$filedisk[$fileid] = [$fileid, $y, $disk[0]];
#			if($filedir[$fileid][0]>480 && $filedir[$fileid][0]<500){
#			print "$filedir[$fileid][0] $filedir[$fileid][1] $disk[1]\n"; 
#			print "$files[$fileid][0] $files[$fileid][1] $files[$fileid][2] $files[$fileid][3]\n";
#			}
		}
	}
}

#dirsizes
for($lastparent=@diridlist-1, $x=0, $fileid=@files-1; $fileid>0; $fileid--){
	if($filedir[$fileid][1] != $diridlist[$lastparent]){
		$files[$diridlist[$lastparent]][3] += $x;
		$x = 0;
		print "$files[$diridlist[$lastparent]][0] $files[$diridlist[$lastparent]][1] $files[$diridlist[$lastparent]][2] $files[$diridlist[$lastparent]][3]\n";
		$lastparent--;
	}
	$x += $files[$fileid][3];
}
$files[0][3] += $x;
print "$files[0][0] $files[0][1] $files[0][2] $files[0][3]\n";

print "\n\nWriting File DB...\n(1 dot = 1%)\n\n";
my $div = @files/100;
my $result;
for($x = $y = 0; $x<@files; $x++){
	$success &&= $fins->execute($files[$x][0], $files[$x][1], $files[$x][2], $files[$x][3]);
	if($x/$div > $y) {++$y; print ".";}
}
#$result = ($success ? $dbh->commit : $dbh->rollback);
#unless ($result) { die "Couldn't finish file transaction: " . $dbh->errstr; }

print "\n\nWriting File-Dir DB...\n\n";

for($x = $y = 0; $x<@files; $x++){
	$success &&= $fdirins->execute($filedir[$x][0], $filedir[$x][1]);
	if($x/$div > $y) {++$y; print ".";}
}
#$result = ($success ? $dbh->commit : $dbh->rollback);
#unless ($result) { die "Couldn't finish filedir transaction: " . $dbh->errstr; }

print "\n\nWriting File-Disk DB...\n\n";

for($x = $y = 0; $x<@files; $x++){
	$success &&= $fdskins->execute($filedisk[$x][0], $filedisk[$x][1], $filedisk[$x][2]);
	if($x/$div > $y) {++$y; print ".";}
}
$result = ($success ? $dbh->commit : $dbh->rollback);
unless ($result) { die "Couldn't finish filedisk transaction: " . $dbh->errstr; }

#print "\n\nClosing DB...\n";

#$dbh->disconnect();
