# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2022 mo-azfar, https://github.com/mo-azfar/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::Event::TicketOwnerList;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

	local $Kernel::OM = Kernel::System::ObjectManager->new(
        'Kernel::System::Log' => {
            LogPrefix => 'TicketOwnerList', 
        },
    );
	
    # check needed stuff
    for my $Needed (qw(Data Event Config UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{Data}->{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID in Data!",
        );
        return;
    }

	if ( !$Param{Config}->{DynamicField} )
	{
		 $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "DynamicField Name (ticket-text) must be define in Ticket::EventModulePost###3120-TicketOwnerList to store the data!",
        );
        return;
	}
	
	# get dynamic field objects
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
	
	my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Config}->{DynamicField},
    );
	
	$DynamicField->{ObjectType} ||= 0;
	$DynamicField->{FieldType} ||= 0;
	
	if ( $DynamicField->{ObjectType} ne 'Ticket' )
	{
		 $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ObjectType for $Param{Config}->{DynamicField} is not Ticket or Not Existed.!",
        );
        return;
	}
	
	if ( $DynamicField->{FieldType} ne 'Text' )
	{
		 $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "FieldType for $Param{Config}->{DynamicField} is not Text or Not Existed.!",
        );
        return;
	}
	
    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

	#get list of ticket owner
	my @Owners = $TicketObject->TicketOwnerList(
        TicketID => $Param{Data}->{TicketID},
    );
	
	my @OwnerArray;
	foreach my $TicketOwner (@Owners)
	{
		push @OwnerArray, $TicketOwner->{UserFullname};
	}
	
	#remove duplicate value
	my %UniqueOwner = map{$_=>1}@OwnerArray;
	@OwnerArray = keys %UniqueOwner;
	
	my $OwnerStrg = join(', ', @OwnerArray);
	
	# set the value
    my $Success = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicField,
        ObjectID           => $Param{Data}->{TicketID},
        Value              => $OwnerStrg,
        UserID             => $Param{UserID},
    );

    return 1;
}

1;
