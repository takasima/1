package File::Extension::Validate;

use 5.006;
use strict;
use warnings;
use IO::File;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(validate_extension suggest_extension) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.04';

my %ext_map = (
	'bz2' => qr/^(tbz|bz2)$/,
	'gz'  => qr/^t?gz$/,
	'jpg' => qr/^jpe?g$/,
	'wmv' => qr/^(asf|wmv)$/,
	'tif' => qr/^tiff?$/,
	'rar' => qr/^r(ar|\d\d)$/,
	'doc' => qr/^(doc|docx)$/,
	'xls' => qr/^(xls|xlsx)$/,
	'ppt' => qr/^(ppt|pptx)$/,
);

my %type_map = (
	# Document
	'doc' => qr/\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1\x00/,
	'pdf' => qr/^%PDF-\d[\d\.]+[\r\n]%/,
	'ppt' => qr/\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1\x00/,
	'xls' => qr/\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1\x00/,
	# image
	'bmp' => qr/^BM/,
	'gif' => qr/^GIF8[7,9]a/,
	'jpg' => qr/^\xFF\xD8/,
	'mng' => qr/^\x8aMNG\x0d\x0a\x1a\x0a/,
	'pcd' => qr/^PCD_OPA/,
	'png' => qr/^\x89PNG/,
	'psd' => qr/^8BPS/,
	'ppm' => qr/^P[1-7]/,
	'tif' => qr/^MM\x00\x2a|^II\x2a\x00/,
	'xbm' => qr/\#define\s+\S+\s+\d+/,
	'xpm' => qr/\/\* XPM \*\//,
	'swf' => qr/^[FC]WS/,
	# archive
	'bz2' => qr/^BZh91AY&SY/,
	'cab' => qr/^MSCF/,
	'gca' => qr/^GCA0/,
	'gz'  => qr/^\x1f\x8b/,
	'ish' => qr/^<<< /,
	'lzh' => qr/^..-(lz[s45]|lh[0-7d])-/,
	'rar' => qr/^Rar\!/,
	'sit' => qr/^StuffIt/,
	'tar' => \&is_tar,
	'yz1' => qr/^yz010500/,
	'zip' => qr/^PK/,
	# audio and video
	'mp3' => qr/^(\x00*\xFF\xFB..\x00|ID3\x03\x00{4}|\x00+$)/,
	'ogm' => qr/^OggS\x00.*vorbis/,
	'wmv' => qr/^\x30\x26\xB2\x75\x8E\x66\xCF\x11\xA6\xD9\x00\xAA\x00\x62\xCE\x6C/,
);

sub read_header {
	my ($class, $file) = @_;
	my $header = "";
	return undef unless (ref($file) eq '' and -f $file);
	my $fh = IO::File->new($file) or return undef;
	$fh->read($header, 255);
	$fh->close;
	return $header;
}

sub get_ext { 
	my ($class, $file) = @_;
	return undef unless (ref($file) eq '' and length($file));
	return undef unless ($file =~ /[^\.\\\/:]\.([^\.\\\/:]+)$/);
	return $1;
}

sub get_typical_ext {
	my ($class, $file) = @_;
	my $ext = lc($class->get_ext($file));
	return undef unless (defined($ext));
	if (not $type_map{$ext}) {
		foreach (keys(%ext_map)) {
			next unless ($ext =~ $ext_map{$_});
			$ext = $_;
			last;
		}
	}
	return ($type_map{$ext}) ? $ext : undef;
}

sub is_valid {
	my ($class, $header, $ext) = @_;
	if    (ref($type_map{$ext}) eq 'Regexp') { return ($header =~ $type_map{$ext}) ? 1 : 0; }
	elsif (ref($type_map{$ext}) eq 'CODE')   { return &{$type_map{$ext}}($header); }
#	print "not $ext : ", join(', ', pack('h2' x 10, $header)), "\n";
	return 0;
}

sub validate {
	my ($class, $file) = @_;
	my $ext = $class->get_typical_ext($file) or return undef;
	my $header = $class->read_header($file) or return undef;
	return $class->is_valid($header, $ext);
}

sub suggest {
	my ($class, $file) = @_;
	my $header = $class->read_header($file) or return undef;
	if (my $prior_ext = $class->get_typical_ext($file)) {
		return $class->get_ext($file) if ($class->is_valid($header, $prior_ext));
	}
	foreach my $ext (keys(%type_map)) {
		return $ext if ($class->is_valid($header, $ext));
	}
	return (-B $file) ? 'bin' : (-T $file) ? 'txt' : undef;
}

sub is_tar {
	my $header = shift;
	my @fields = (
	#	[FIELD_NAME, OFFSET, SIZE, VALID_REGEX],
		['name', 0, 100, qr/^[^\x00]+\x00*$/],
		['mode', 100, 8, qr/^[0-9\x20]{7}\x00$/],
		['uid', 108, 8, qr/^[0-9\x20]{7}\x00$/],
		['gid', 116, 8, qr/^[0-9\x20]{7}\x00$/],
		['size', 124, 12, undef],
		['mtime', 136, 12, qr/^[\x00\x20-\x7f]{12}$/],
		['chksum', 148, 8, qr/^[\x00\x20-\x7f]{8}$/],
		['typeflag', 156, 1, qr/^[\x20-\x7f]$/],
		['linkname', 157, 100, qr/^[^\x00]*\x00*$/],
	);
	foreach my $field (@fields) {
		next unless ($field->[3]);
		last if (length($header) < $field->[1]);
		my ($name, $value, $regex) = ($field->[0], substr($header, $field->[1], $field->[2]), $field->[3]);
		next if ($value =~ $regex);
		return 0;
	}
	return 1;
}

sub validate_extension { return File::Extension::Validate->validate(@_); }
sub suggest_extension  { return File::Extension::Validate->suggest(@_); }
sub test {
	my ($class, $target, $max_depth, $depth) = @_;
	die "Target file/directory does not specified." unless (defined($target) and length($target));
	die "\"$target\" does not exist." unless (-e $target);
	$max_depth = 1 if (not defined($max_depth) and -d $target);
	$depth = 0 if (not defined($depth));
	if (-f $target) {
		my $file = $1 if ($target =~ /([^\\\/:]+)$/);
		my $ext = $class->get_ext($target);
		my $type = $class->get_typical_ext($target);
		if (defined($type)) {
			printf("  %-30s : %s(%s)", $file, $ext, $type);
			my $result = $class->validate($target);
			if    (not defined($result)) { print " ... error\n"; }
			elsif (not $result)          { print " --> " . $class->suggest($target) . "\n"; }
			else                         { print " ... ok\n"; }
		} else {
			printf("  %-30s : %s(unknown)\n", $file, $ext);
		}
	} elsif (-d $target) {
		my @nodes = glob("$target/*");
		my @files = sort { lc($a) cmp lc($b) } grep { -f $_ and defined($class->get_typical_ext($_)) } @nodes;
		my @dirs = ($max_depth > $depth) ? sort { lc($a) cmp lc($b) } grep { -d $_ } @nodes : ();
		print "[$target]\n" if (@files);
		map { $class->test($_, $max_depth, $depth + 1); $_; } (@files, @dirs);
	}
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

File::Extension::Validate - Perl extension for validate file extension.

=head1 SYNOPSIS

  use File::Extension::Validate;
  my $file = 'file1.tar';
  if (File::Extension::Validate->validate($file) == 0) {
      print "$file has invalid extension!";
      if (my $ext = File::Extension::Validate->suggest($file)) {
          print "'$ext' is my suggestion.";
      }
  }
  
  ---- or ----
  use File::Extension::Validate qw(:all);
  my $file = 'file1.tar';
  if (&validate_extension($file) == 0) {
      print "$file has invalid extension!";
      if (my $ext = &suggest_extension($file)) {
          print "'$ext' is my suggestion.";
      }
  }

=head1 DESCRIPTION

File::Extension::Validate allow you to check if file has valid extension.

=head1 Method

=over 4

=item File::Extension::Validate->validate('FILENAME');

This method returns 1 when file extension looks valid, 0 when invalid.
When the extension is unknows for File::Extension::Validate, it returns undef.

=item $ext = File::Extension::Validate->suggest('FILENAME');

This method suggest valid extension.
When File::Extension::Validate can not suggest anythihng, it returns 'txt' or 'bin'.

=item $ext = File::Extension::Validate->is_valid('HEADER_STR', 'EXTENSION');

This method returns 1 when 'HEADER_STR' is valid header of 'EXTENSION', 0 when invalid.
When the 'EXTENSION' is unknows for File::Extension::Validate, it returns undef.

=back

=head2 EXPORT

None by default.

=over 4

=item &validate_extension('FILENAME');

This is not-OO alias of File::Extension::Validate->validate.

=item &suggest_extension('FILENAME');

This is not-OO alias of File::Extension::Validate->suggest.

=back

=head1 AUTHOR

Makio Tsukamoto <tsukamoto@gmail.com>

=head1 SEE ALSO

L<perl>.

=cut
