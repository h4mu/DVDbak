CREATE TABLE IF NOT EXISTS file (
	id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	name VARCHAR NOT NULL CHECK( name <> "." AND name <> ".."),
	dir BOOL NOT NULL DEFAULT TRUE, 
	size INTEGER NOT NULL DEFAULT 4096);

CREATE TABLE IF NOT EXISTS disk (
	id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	name VARCHAR,
	size INTEGER NOT NULL DEFAULT 4500000000,
	percent NUMBER(3,2) DEFAULT 0);
	  
CREATE TABLE IF NOT EXISTS filedir (
	fileid INTEGER,
	dirid INTEGER);

CREATE TABLE IF NOT EXISTS filedisk (
	fileid INTEGER,
	url VARCHAR,
	diskid INTEGER);

CREATE INDEX IF NOT EXISTS ifilename ON file (dir, name);
CREATE INDEX IF NOT EXISTS ifilesize ON file (size);
CREATE INDEX IF NOT EXISTS idiskname ON disk (name);
CREATE INDEX IF NOT EXISTS idisksize ON disk (size);
CREATE INDEX IF NOT EXISTS idiskpercent ON disk (percent);
CREATE INDEX IF NOT EXISTS idiskname ON disk (name);
CREATE INDEX IF NOT EXISTS ifilediskfilename ON filedisk (fileid);
CREATE INDEX IF NOT EXISTS ifilediskurl ON filedisk (url);
CREATE INDEX IF NOT EXISTS ifilediskdiskname ON filedisk (diskid);
CREATE INDEX IF NOT EXISTS ifiledirfilename ON filedir (fileid);
CREATE INDEX IF NOT EXISTS ifiledirdirname ON filedir (dirid);

INSERT OR IGNORE INTO disk (id, name, size, percent) VALUES(0, "/dev/sda3", 150000000000, 0);
