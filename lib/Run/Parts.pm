package Run::Parts;

# ABSTRACT: Offers functionality of Debian's run-parts tool in Perl

use Modern::Perl;

use File::Slurp 9999.17;
use Run::Parts::Common;

=encoding utf8

=head1 SYNOPSIS

Run::Parts offers functionality of Debian's L<run-parts(8)> tool in
Perl.

run-parts runs all the executable files named within constraints
described in L<run-parts(8)> and L<Run::Parts::Perl>, found
in the given directory.  Other files and directories are silently
ignored.

Additionally it can just print the names of the all matching files
(not limited to executables, but ignores blacklisted files like
e.g. backup files), but don't actually run them.

This is useful when functionality or configuration is split over
multiple files in one directory. A typical convention is that the
directory name ends in ".d". Common examples for such splitted
configuration directories:

    /etc/cron.d/
    /etc/apt/apt.conf.d/
    /etc/apt/sources.list.d/,
    /etc/aptitude-robot/pkglist.d/
    /etc/logrotate.d/
    /etc/rsyslog.d/

Perhaps a little code snippet.

    use Run::Parts;

    my $rp  = Run::Parts->new('directory'); # chooses backend automatically
    my $rpp = Run::Parts->new('directory', 'perl'); # pure perl backend
    my $rpd = Run::Parts->new('directory', 'debian'); # uses /bin/run-parts

    my @file_list        = $rp->list;
    my @executables_list = $rpp->test;
    my $commands_output  = $rpd->run;
    ...

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme


=head1 BACKENDS

L<Run::Parts> contains two backend implementations.
L<Run::Parts::Debian> actually uses /bin/run-parts and
L<Run::Parts::Perl> is a pure Perl implementation of a basic set of
L<run-parts(8)>' functionality.

L<Run::Parts::Debian> may or may not work with RedHat's simplified
shell-script based reimplementation of Debian's L<run-parts(8)>.

By default L<Run::Parts> uses L<Run::Parts::Debian> if /bin/run-parts
exists, L<Run::Parts::Perl> otherwise. But you can also choose any of
the backends explicitly.


=for readme stop

=head1 METHODS

=head2 new (Constructor)

Creates a new L<Run::Parts> object. Takes one parameter, the directory
on which run-parts should work.

=cut

sub new {
    my $self = {};
    bless($self, shift);
    $self->{dir} = shift;

    my $backend = shift;
    if (defined $backend) {
        if (ref $backend) {
            $self->{backend} = $backend->new($self->{dir});
        } elsif ($backend eq 'debian' or $backend eq 'run-parts') {
            use Run::Parts::Debian;
            $self->{backend} = Run::Parts::Debian->new($self->{dir});
        } elsif ($backend eq 'perl' or $backend eq 'module') {
            use Run::Parts::Perl;
            $self->{backend} = Run::Parts::Perl->new($self->{dir});
        } else {
            warn "Unknown backend $backend in use";
            require $backend;
            $self->{backend} = $backend->new($self->{dir});
        }
    } else {
        if (-x '/bin/run-parts') {
            $self->{backend} = Run::Parts::Debian->new($self->{dir});
        } else {
            $self->{backend} = Run::Parts::Perl->new($self->{dir});
        }
    }

    return $self;
}

=head2 run_parts_command

Returns the L<run-parts(8)> command to run with the given command
parameter.

=cut

sub run_parts_command {
    my $self = shift;
    return $self->{backend}->run_parts_command(@_);
}

=head2 list

Lists all relevant files in the given directory. Equivalent to
"run-parts --list".

=cut

sub list {
    my $self = shift;
    return $self->run_parts_command('list');
}

=head2 test

Lists all relevant executables in the given directory. Equivalent to
"run-parts --test".

=cut

sub test {
    my $self = shift;
    return $self->run_parts_command('test');
}

=head2 run

Runs all relevant executables in the given directory. Equivalent to
"run-parts".

=cut

sub run {
    my $self = shift;
    return $self->run_parts_command();
}

=head2 concat

Returns the concatenated contents of all relevant files in the given
directory. Equivalent to "cat `run-parts --list`".

=cut

sub concat {
    my $self = shift;
    return lines(map { read_file($_, { chomp => 1 }) } $self->list());
}

=for readme continue

=head1 SEE ALSO

L<run-parts(8)>, L<Run::Parts::Debian>, L<Run::Parts::Perl>

=head1 BUGS

Please report any bugs or feature requests to C<bug-run-parts at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Run-Parts>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 CODE

You can find a git repository of Run::Parts' code at
L<https://github.com/xtaran/run-parts>.


=head1 SUPPORT

=begin readme

You can find documentation for this module with the perldoc command.

    perldoc Run::Parts


You can also look for information at:

=end readme

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Run-Parts>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Run-Parts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Run-Parts>

=item * Search CPAN

L<http://search.cpan.org/dist/Run-Parts/>

=back
=cut

1; # End of Run::Parts
