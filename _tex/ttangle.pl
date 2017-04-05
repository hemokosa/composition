#!/usr/bin/env perl
#
# ttangle - Tex Tangle
#
&prologue;
&main;
&epilogue;

sub prologue {
  require 'cacheout.pl';
  if($#ARGV < 0){
    print STDERR "ttangle --- Tex Tangle\n";
    print STDERR "Usage: ttangle documentfiles\n";
    exit 0;
  }
  $SIG{'INT'} = $SIG{'TERM'} =
  $SIG{'QUIT'} = $SIG{'HUP'} = 'finish';
}

sub main {
  while($file = shift(@ARGV)){
    unless(open(f,$file)){
      print STDERR "Can't open <$file>\n";
      &finish;
    }
    while(){
      if(m#^$(J\(Bend{Verbatim}$#){
        @tmpfiles = ();
      }
      elsif(m#^$(J\(Bbegin{Verbatim}$#){
        @files = split(/,/,$1);
        @tmpfiles = ();
        foreach $file (@files){
          $allfiles{$file} = 1;
          push(@tmpfiles,&tmpname($file));
        }
      }
      else {
        foreach $tmpfile (@tmpfiles){
          &cacheout($tmpfile);
          $taghead = pack(c,60);
          s/&.{0}lt;/$taghead/g;
          print $tmpfile $_;
        }
      }
    }
    close(f);
  }
}

sub epilogue {
  foreach $file (keys %allfiles){
    $tmpfile = &tmpname($file);
    close($tmpfile);
    if(! -e $file || &diff($tmpfile,$file)){
      push(@newfiles,$file);
      &move($tmpfile,$file);
      chmod 0555,$file;
    }
  }
  sort @newfiles;
  $n = $#newfiles + 1;
  print STDERR 
    $n == 0 ? "No file is updated.\n" :
    $n == 1 ? "File '$newfiles[0]' is updated.\n" :
      "Files '".join("', '",@newfiles[0..$n-2]).
      "' and '".$newfiles[$n-1]."' are updated.\n";
  &finish;
}

sub tmpname {
  local($_) = @_;
  s#/#_#g;
  "/tmp/stangle$_$$";
}

sub finish {
  foreach $file (keys %allfiles){
    $tmpfile = &tmpname($file);
#    unlink($tmpfile) if -e $tmpfile;
  }
  exit;
}

sub move {
  local($from,$to) = @_;
  return if $from eq $to;
  system "/bin/mv -f $from $to";
  if($?){
    print STDERR "Can't move $from to $to\n";
    &finish;
  }
}

sub diff {
  local($file1,$file2) = @_;
  system "/usr/bin/diff $file1 $file2 > /dev/null";
  $? >> 8;
}

