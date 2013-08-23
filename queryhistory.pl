# QueryHistory by Alex Meade <hatboy112@yahoo.com>
#
use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '20130823';
%IRSSI = (
    authors     => 'Alex \'ameade\'Meade',
    contact     => 'hatboy112@yahoo.com',
    name        => 'QueryHistory',
    description => 'Loads history of a conversation of a query on re-creation',
    license     => 'GPLv2',
    modules     => 'Date::Format File::Glob Time::Local',
    changed     => $VERSION,
);  

use Irssi 20020324;
use Date::Format;
use File::Glob ':glob';
use Time::Local;

sub sig_window_item_new ($$) {
    my ($win, $witem) = @_;
    return unless (ref $witem && $witem->{type} eq 'QUERY');
    my @data;
    my $lines = Irssi::settings_get_int('queryhistory_line_limit');
    my $days = Irssi::settings_get_int('queryhistory_day_limit');
    my $day_count = $days;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();

    while (($day_count >=0) && (@data < $lines))
    {
        my $filename = Irssi::settings_get_str('autolog_path');
        my $servertag = $witem->{server}->{tag};
        my $name = lc $witem->{name};
        $filename =~ s/(\$tag|\$1)/$servertag/g;
        $filename =~ s/\$0/$name/g;

        my $zone;
        my $tm = timelocal(0, 0, 12, $mday, $mon, $year) - 24*60*60*$day_count;
        my @lt = localtime($tm);
        my $date_stamp = strftime('%m/%d/%y', @lt, $zone);
        push(@data, "Date changed to $date_stamp\n");
	shift(@data) if (@data > $lines);

        $filename = strftime($filename, @lt, $zone);
        $filename =~ s/(\[|\])/\\$1/g;
        local *F;
        open(F, "<".bsd_glob($filename));
        my $item;
        foreach $item (<F>) {
            if ($item =~ /\[.*\]/ or $item =~ /\<.*\>/)
            {
                push(@data, $item);
                shift(@data) if (@data > $lines);
            }
        }
	$day_count --;
    }
    my $text;
    foreach (@data)
    {
        $text .= $_;
    }
    $text =~ s/%/%%/g;
    $witem->print($text, MSGLEVEL_CLIENTCRAP) if $text;
}

Irssi::settings_add_int($IRSSI{name}, 'queryhistory_line_limit', 1000);
Irssi::settings_add_int($IRSSI{name}, 'queryhistory_day_limit', 30);

Irssi::signal_add('window item new', 'sig_window_item_new');

