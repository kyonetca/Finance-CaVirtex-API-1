#!/usr/bin/perl -wT

use 5.010;
use warnings;
use strict;
use lib qw(.);

use Finance::CaVirtex::API;
use Data::Dumper;

use constant DEBUG => 1;

# Your CaVirtex API token and secret go here...
use constant API_TOKEN          => 'CaVirtex token  here';
use constant API_SECRET         => 'CaVirtex secret here';

use constant TEST_CURRENCY_PAIR => 'BTCCAD';

use constant TEST_TICKER        => 0;
use constant TEST_TRADEBOOK     => 0;
use constant TEST_ORDERBOOK     => 0;

use constant TEST_PRIVATE       => 1;

use constant TEST_BALANCE       => 1;
use constant TEST_TRANSACTIONS  => 0;
use constant TEST_TRADE_HISTORY => 0;
use constant TEST_ORDER_HISTORY => 0;
use constant TEST_ORDER         => 0;
use constant TEST_ORDER_CANCEL  => 0;
# If you really want to do this test, then set the EXTERNAL_BITCOIN_ADDRESS to something as well...
use constant TEST_WITHDRAW      => 0;
use constant EXTERNAL_BITCOIN_ADDRESS => 'set to your own btc wallet address outside CaVirtex';

main->new->go;

sub new { bless {} => shift }

sub set_public  { shift->processor(Finance::CaVirtex::API->new) }
sub set_private {
    my $self = shift;
warn "set_private";
    $self->processor(Finance::CaVirtex::API->new(secret => API_SECRET, token => API_TOKEN));
    #shift->processor(Finance::CaVirtex::API->new 
}

sub processor { my $self = shift; $self->get_set(@_) }
sub get_set   {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

sub go  {
    my $self = shift;

    say '=== Begin PUBLIC tests';
    $self->set_public;
    if (TEST_TICKER) {
        print '=== Ticker...';
        my $ticker = $self->processor->ticker;
        if ($ticker) {
            say 'success';
            say Dumper $ticker if DEBUG;
            say "\n\tproof:";
            foreach my $currency (keys %$ticker) {
               printf "\t%s last traded at %s\n", $currency, $ticker->{$currency}->{last};
            }
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->processor->error if DEBUG;
        }
    }

    if (TEST_TRADEBOOK) {
        print '=== Tradebook...';
        my $tradebook = $self->processor->tradebook(currencypair => TEST_CURRENCY_PAIR);
        if ($tradebook) {
            say 'success';
            say Dumper $tradebook if DEBUG;
            say "\n\tproof:";
            printf "\tI see %d trades\n", scalar @$tradebook;
            printf "\tI see one trade of %s %s for \$%s %s at a rate of \$%s %s/%s [unixtime: %s]\n", @{$tradebook->[0]}{qw(for_currency_amount for_currency trade_currency_amount trade_currency rate trade_currency for_currency date)};
            # I see a trade of 0.22 BTC for $116 CAD at a rate of $580/BTC [unixtime: 1401001012].
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->processor->error if DEBUG;
        }
    }

    if (TEST_ORDERBOOK) {
        print '=== Orderbook...';
        my $orderbook = $self->processor->orderbook(currencypair => TEST_CURRENCY_PAIR);
        if ($orderbook) {
            say 'success';
            say Dumper $orderbook if DEBUG;
            say "\n\tproof:";
            printf "\tI see %s bids\n", scalar @{$orderbook->{bids}};
            my @sorted_bids = sort {$b->[0] <=> $a->[0]} @{$orderbook->{bids}};
            printf "\tThe best bid in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_bids[0]}[1,0];
            printf "\tThe next bid in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_bids[1]}[1,0] if scalar @sorted_bids > 1;
 
            printf "\tI see %s asks\n", scalar @{$orderbook->{asks}};
            my @sorted_asks = sort {$a->[0] <=> $b->[0]} @{$orderbook->{asks}};
            printf "\tThe best ask in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_asks[0]}[1,0];
            printf "\tThe next ask in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_asks[1]}[1,0] if scalar @sorted_asks > 1;
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->processor->error if DEBUG;
        }
    }
    say '=== Done PUBLIC tests';

    if (TEST_PRIVATE) {
        say '=== Begin PRIVATE tests';
        $self->set_private;
        ## this is a bad trick...
        #$self->{processor} = Finance::CaVirtex::API->new(
            #token  => API_TOKEN,
            #secret => API_SECRET,
        #);

        if (TEST_BALANCE) {
            say 'Balance...';
            my $balance = $self->processor->balance();
            if ($balance) {
                say 'success';
                say Dumper $balance if DEBUG;
                foreach my $currency (qw(CAD BTC LTC)) {
                    printf "Your %s balance is: %s\n", $currency, $balance->{currency};
                }
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }

        if (TEST_TRANSACTIONS) {
            say 'Transactions...';
            my $transactions = $self->processor->transactions(currencypair => 'BTCCAD');
            if ($transactions) {
                say 'success';
                say Dumper $transactions if DEBUG;
                foreach my $transaction (@$transactions) {
                    printf "Transaction [%s]: %s %s %s\n", @{$transaction}{qw(reason total currency)};
                }
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }

        if (TEST_TRADE_HISTORY) {
            say 'Trade History...';
            my $trade_history = $self->processor->trade_history(currencypair => 'BTCCAD');
            if ($trade_history) {
                say 'success';
                say Dumper $trade_history if DEBUG;
                foreach my $trade (@$trade_history) {
                    #Bought 0.5 BTC @ 345.6 CAD/BTC for a total of 250.34 CAD
                    printf "Trade [%s, oid:%s]: bought %s %s @ %s %s/%s for a total of %s %s\n", @{$trade}{qw(id oid for_currency_amount for_currency rate trade_currency for_currency trade_currency_amount trade_currency)};
                }
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }

        if (TEST_ORDER_HISTORY) {
            say 'Order History...';
            my $order_history = $self->processor->order_history(currencypair => 'BTCCAD');
            if ($order_history) {
                say 'success';
                say Dumper $order_history if DEBUG;
                foreach my $order (@$order_history) {
                    say 'Order: ' . join(' ', values @$order);
                }
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }

        if (TEST_ORDER) {
            say 'Order...';
            my $currencypair = 'BTCCAD';
            my $mode         = 'buy';
            my $amount       = '1.00001';
            my $price        = '0.01';
            my $order = $self->processor->order(
                currencypair => $currencypair,
                mode         => $mode,
                amount       => $amount,
                price        => $price,
            );
            if ($order) {
                say 'success';
                say Dumper $order if DEBUG;
                printf "Placed Order. status: %s, id: %s, success: %s\n", @{$order}{qw(status id success)};
                if (TEST_ORDER_CANCEL) {
                    say 'Order Cancel...';
                    my $id = $order->{id};
                    my $order_cancel = $self->processor->order_cancel(id => $id);
                    if ($order_cancel) {
                        say 'success';
                        say Dumper $order_cancel if DEBUG;
                        printf "Cancelled Order ID: %s\n", $order_cancel->{id};
                    }
                    else {
                        say 'failed';
                        say Dumper $self->processor->error if DEBUG;
                    }
                }
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }

        if (TEST_WITHDRAW) {
            say 'Withdraw...';

            # are you kidding me??? you want to withdraw BTC on a test???
            die 'Are you nuts? You will have to change this code to test a withdrawal';

            my $amount   = '0.00000001';
            my $currency = 'BTC';

            my $withdraw = $self->processor->withdraw(amount => $amount, currency => $currency, address => EXTERNAL_BITCOIN_ADDRESS);
            if ($withdraw) {
                say 'success';
                say Dumper $withdraw if DEBUG;
                printf "Withdrawal [%s]: %s %s %s %s to %s with a fee of %s %s\n", @{$withdraw}{qw(publictransactionid user reason amount currency wallet fee currency)};
            }
            else {
                say 'failed';
                say Dumper $self->processor->error if DEBUG;
            }
        }
        say '=== Done PRIVATE tests';
    }
}

1;

__END__

