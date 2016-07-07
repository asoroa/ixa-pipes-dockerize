#!/usr/bin/perl

use strict;
use JSON;
use File::Basename;

my $C = &read_config("config.json");
my $LANG = $C->{language};
if (not defined $LANG) {
    warn "No language set. Default to 'en'\n";
    $LANG = "en";
}

my @autoruns = ("cat");
my $dockerfile = "";
foreach my $pipe (@{ $C->{pipeline} }) {
    die "Can't locate $pipe in config file\n" unless defined $C->{pipes}->{$pipe};
    $dockerfile .= &dockerfile($C->{pipes}->{$pipe});
    push @autoruns, &autorun($C->{pipes}->{$pipe});
}

&write_dockerfile($dockerfile);
&write_autorun(\@autoruns);

sub write_dockerfile {
    my $content = shift;
    my $fname = "Dockerfile";
    rename "$fname","$fname~" if -e "$fname";
    open(my $fo, ">$fname") or die "Can't create $fname\n";
    print $fo "FROM java\n";
    print $fo "RUN mkdir model\n";
    print $fo "$content\n";
    print $fo 'COPY docker_autorun.sh docker_autorun.sh'."\n";
    print $fo 'CMD ["/docker_autorun.sh"]'."\n";
}

sub write_autorun {
    my $A = shift;
    my $fname = "docker_autorun.sh";
    rename "$fname","$fname~" if -e "$fname";
    open(my $fo, ">$fname") or die "Can't create $fname\n";
    print $fo "#!/bin/bash\n";
    print $fo join(" | ", map { "$_ 2>/dev/null" } @ { $A }) . " 2>/dev/null"."\n";
    $fo->close();
    chmod 0770, $fname;
}
sub dockerfile {

    my ($config) = @_;

    my $hostjar = $config->{'jar'};
    die "[E] $hostjar does not exist\n" unless -e $hostjar;
    my $dockerjar = basename($hostjar);
    my $content = "COPY $hostjar $dockerjar\n";
    if (defined $config->{models}) {
        foreach my $h ( @{ $config->{models} } ) {
            my $hostfile = $h->{file};
            die "[E] $hostfile does not exist\n" unless -e $hostfile;
            my $dockerfile = basename $hostfile;
            $content .= "COPY $hostfile $hostfile\n";
        }
    }
    return $content;
}

sub autorun {

    my ($config) = @_;

    my $hostjar = $config->{'jar'};
    die "[E] $hostjar does not exist\n" unless -e $hostjar;
    my $dockerjar = basename($hostjar);
    my $models_cli;
    if (defined $config->{models}) {
        my @A;
        foreach my $h (@{ $config->{models} }) {
            my $cli_opt = $h->{'cli-opt'};
            substr($cli_opt, 0, 0) = "-" unless $cli_opt =~ /^\s*-/;
            push @A, $cli_opt . " " . $h->{'file'};
        }
        $models_cli = join(" ", @A);
    }
    my $content = $config->{run};
    $content =~ s/\n//;
    $content =~ s/\$\{lang\}/$LANG/go;
    $content =~ s/\$\{hostjar\}/$hostjar/go;
    $content =~ s/\$\{dockerjar\}/$dockerjar/go;
    $content =~ s/\$\{models_cli\}/$models_cli/go;
    return $content;
}

sub read_skel {
    my ($fname) = @_;

    open(my $fh, $fname) or die "$fname:$!\n";
    binmode $fh, ":utf8";
    my @A;
    while(<$fh>) {
        next if /^\#/;
        next if /^\s*$/;
        push @A, $_;
    }
    return join("", @A);
}

sub read_config {

    my $fname = shift;
    open(my $fh, $fname) or die "$fname: $!\n";
    binmode $fh, ":utf8";
    my @A = <$fh>;
    # while (<$fh>) {
    #     chomp;
    #     push @A;
    # }
    return from_json(join("", @A));
}
