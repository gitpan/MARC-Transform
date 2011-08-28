#!/usr/bin/perl
use Data::Compare;
use strict;
use warnings;
use lib qw( lib ../lib );
use YAML;
use Test::More 'no_plan';
BEGIN {
    use_ok( 'MARC::Transform' );
}

sub recordtostring {
	my ($record) = @_;
	my $string="";
	my $finalstring=$record->leader;
	my %tag_names = map( { $$_{_tag} => 1 } $record->fields);
	my @order = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	foreach my $tag(sort({ $a cmp $b } keys(%tag_names)))
	{
		my @fields=$record->field($tag);
		foreach my $field(@fields)
		{
			$string.="|#f#|$tag:";
			if ($field->is_control_field())
			{
				$string.=$field->data();
			}
			else
			{
				$string.=$field->indicator(1);
				$string.=$field->indicator(2);
				foreach my $key (@order)
				{
					foreach my $subfield (sort({ $a cmp $b } $field->subfield($key)))
					{
						$string.="|$key:".$subfield;
					}
				}
			}
		}
	}
	my @arec = split(/\|#f#\|/,$string);#warn Data::Dumper::Dumper @arec;
	foreach my $tempstring (sort({ $a cmp $b } @arec))
	{
		$finalstring.="||$tempstring";
	}
	return $finalstring;
}

my $record = MARC::Record->new();
$record->leader('optionnal leader');
$record->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content' ));
$record->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8b' ));
$record->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8a' ));
$record->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'foao', 'b' => '1', 'b' => 'baoar', 'c' => 'big') );
$record->insert_fields_ordered( MARC::Field->new( '501', '', '', 'c' => '1') );
$record->insert_fields_ordered( MARC::Field->new( '106', '', '', 'a' => 'VaLuE') );
$record->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'fee', 'a' => 'babar') );
$record->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'zut', 'a' => 'sisi') );
$record->insert_fields_ordered( MARC::Field->new( '604', '', '', 'a' => 'foo', 'a' => 'foo', 'b' => 'bar', 'c' => 'truc') );
$record->insert_fields_ordered( MARC::Field->new( '401', '', '', 'a' => 'afooa') );
$record->insert_fields_ordered( MARC::Field->new( '402', '1', '', 'a' => 'a402a1') );
$record->insert_fields_ordered( MARC::Field->new( '402', '', '2', 'a' => 'a402a2') );

my @yaml = YAML::Load(
'---
condition : $f501a eq "foo"
create :
 f502a : this is the value of a subfield of a new 502 field
---
condition : $f401a=~/foo/
create :
 b : new value of the 401 conditions field
 f600 :
  a : 
   - first a subfield of this new 600 field
   - second a subfield of this new 600 field
  b : the 600b value
execute : \&reencodeRecordtoUtf8()
---
-
 condition : $f501a =~/foo/ and $f503a =~/bar/
 forceupdate :
  $f503b : mandatory b in condition\'s field
  f005_ : mandatory 005
  f006_ : \&return_record_encoding()
  f700 :
   a : the a subfield of this mandatory 700 field
   b : \&sub1("$f503a")
 forceupdatefirst :
  $f501b : update only the first b in condition\'s field 501
-
 condition : $f501a =~/foo/
 execute : \&warnfoo("f501a contain foo")
-
 subs : >
    sub return_record_encoding { $record->encoding(); }
    sub sub1 { my $string = shift;$string =~ s/a/e/g;return $string; }
    sub warnfoo { my $string = shift;warn $string; }
---
-
 condition : $f501b2 eq "o"
 update :
  c : updated value of all c in condition\'s field
  f504a : updated value of all 504a if exists
  f604 :
   b : \&LUT("$this")
   c : \&LUT("NY","cities")
 updatefirst :
  f604a : update only the first a in 604
-
 condition : $f501c eq "1"
 delete : $f501
-
 LUT :
   1 : first
   2 : second
   bar : openbar
---
delete :
 - f401a
 - f005
---
condition : $ldr2 eq "t"
execute : \&SetRecordToLowerCase($record)
---
condition : $f008_ eq "controlfield_content8b"
duplicatefield :
 - $f008 > f007
 - f402 > f602
delete : f402
---
global_subs: >
    sub reencodeRecordtoUtf8 {
        $record->encoding( \'UTF-8\' );
    }
    sub warnfee {
        my $string = shift;warn $string;
    }
global_LUT:
 cities:
  NY : New York
  SF : San Fransisco
 numbers:
  1 : one
  2 : two
'
);

#print "\n------------record before filter----------------\n".$record->as_formatted."\n------------ end of record before filter -------------\n";
$record = MARC::Transform->new($record,\@yaml);
#print "\n------------record after filter----------------\n".$record->as_formatted."\n------------ end of after before filter -------------\n";
my $v1=YAML::Dump recordtostring($record);
my $v2=YAML::Dump "optionnalaleader||||006:UTF-8||007:controlfield_content8b||008:controlfield_content8a||008:controlfield_content8b||106:  |a:VaLuE||401:  |b:new value of the 401 conditions field||501:  |a:foao|a:foo|b:baoar|b:update only the first b in condition's field 501|c:updated value of all c in condition's field||501:  |c:1||502:  |a:this is the value of a subfield of a new 502 field||503:  |a:babar|a:fee|b:mandatory b in condition's field||504:  |a:updated value of all 504a if exists|a:updated value of all 504a if exists||600:  |a:first a subfield of this new 600 field|a:second a subfield of this new 600 field|b:the 600b value||602: 2|a:a402a2||602:1 |a:a402a1||604:  |a:foo|a:update only the first a in 604|b:openbar|c:New York||700:  |a:the a subfield of this mandatory 700 field|b:beber";
ok(Compare($v1,$v2))
    or diag(Dump $v1);
