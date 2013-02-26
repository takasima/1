# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::L10N::nl;

use strict;
use base 'MT::Enterprise::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Enterprise.pack/app-cms.yaml
	'Groups ([_1])' => 'Groepen ([_1])',
	'Are you sure you want to delete the selected group(s)?' => 'Bent u zeker dat u de geselecteerde groep(en) wenst te verwijderen?',
	'Are you sure you want to remove the selected member(s) from the group?' => 'Bent u zeker dat u de geselecteerde leden of het geselcteerde lid wenst te verwijderen uit de groep?',
	'[_1]\'s Group' => 'Groep van [_1]',
	'Groups' => 'Groepen',
	'Manage Member' => 'Lid beheren',
	'Bulk Author Export' => 'Auteurs exporteren in bulk',
	'Bulk Author Import' => 'Auteurs importeren in bulk',
	'Synchronize Users' => 'Gebruikers synchroniseren',
	'Synchronize Groups' => 'Groepen synchroniseren',
	'Add user to group' => 'Gebruiker toevoegen aan een groep',

## addons/Enterprise.pack/app-wizard.yaml
	'This module is required in order to use the LDAP Authentication.' => 'Deze module is vereist als u LDAP authenticatie wenst te gebruiken.',

## addons/Enterprise.pack/config.yaml
	'http://www.sixapart.com/movabletype/' => 'http://www.sixapart.com/movabletype',
	'Permissions of group: [_1]' => 'Permissies van groep: [_1]',
	'Group' => 'Groep',
	'Groups associated with author: [_1]' => 'Groepen geassocieerd met auteur: [_1]',
	'Inactive' => 'Inactief',
	'Members of group: [_1]' => 'Leden van groep: [_1]',
	'Advanced Pack' => 'Advanced pack',
	'User/Group' => 'Gebruiker/groep',
	'User/Group Name' => 'Naam gebruiker/groep',
	'__GROUP_MEMBER_COUNT' => 'Leden',
	'My Groups' => 'Mijn groepen',
	'Group Name' => 'Groepsnaam',
	'Manage Group Members' => 'Groepsleden beheren',
	'Group Members' => 'Groepsleden',
	'Group Member' => 'Groepslid',
	'Permissions for Users' => 'Permissies voor gebruikers',
	'Permissions for Groups' => 'Permissies voor groepen',
	'Active Groups' => 'Actieve groepen',
	'Disabled Groups' => 'Gedeactiveerde groepen',
	'Oracle Database (Recommended)' => 'Oracle database (aangeradenà',
	'Microsoft SQL Server Database' => 'Microsoft SQL Server database',
	'Microsoft SQL Server Database UTF-8 support (Recommended)' => 'Microsoft SQL Server Database met UTF-8 ondersteuning (aangeraden)',
	'Publish Charset' => 'Karakterset voor publicatie',
	'ODBC Driver' => 'ODBC Driver',
	'External Directory Synchronization' => 'Externe directory-synchronisatie',
	'Populating author\'s external ID to have lower case user name...' => 'Extern ID van auteur aan het bevolken zodat de gebruikersnaam in kleine letters staat...',

## addons/Enterprise.pack/lib/MT/Auth/LDAP.pm
	'User [_1]([_2]) not found.' => 'Gebruker [_1]([_2]) niet gevonden.',
	'User \'[_1]\' cannot be updated.' => 'Gebruiker \'[_1]\' kan niet worden bijgewerkt.',
	'User \'[_1]\' updated with LDAP login ID.' => 'Gebruiker \'[_1]\' bijgewerkt met LDAP login ID.',
	'LDAP user [_1] not found.' => 'LDAP gebruiker [_1] niet gevonden.',
	'User [_1] cannot be updated.' => 'Gebruiker [_1] kan niet worden bijgewerkt.',
	'User cannot be updated: [_1].' => 'Gebruiker kan niet worden bijgewerkt: [_1].',
	'Failed login attempt by user \'[_1]\' who was deleted from LDAP.' => 'Mislukte aanmeldpoging van gebruiker \'[_1]\' die werd verwijderd uit LDAP.',
	'User \'[_1]\' updated with LDAP login name \'[_2]\'.' => 'Gebruiker \'[_1]\' bijgewerkt met LDAP loginnaam \'[_2]\'.',
	'Failed login attempt by user \'[_1]\'. A user with that username already exists in the system with a different UUID.' => 'Mislukte aanmeldpoging van gebruiker \'[_1]\'.  Een gebruiker met die gebruikersnaam bestaat al in het systeem met een andere UUID.',
	'User \'[_1]\' account is disabled.' => 'Account van gebruiker \'[_1]\' is niet actief.',
	'LDAP users synchronization interrupted.' => 'LDAP gebruikerssynchronisatie onderbroken',
	'Loading MT::LDAP failed: [_1]' => 'Laden van MT::LDAP mislukt: [_1]',
	'External user synchronization failed.' => 'Externe gebruikerssynchronisatie mislukt.',
	'An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted.' => 'Een poging om alle systeembeheerders in het systeem uit te schakelen werd ondernomen.  Synchronisatie van gebruikers werd onderbroken.',
	'Information about the following users was modified:' => 'Informatie over volgende gebruikers werd bijgewerkt:',
	'The following users were disabled:' => 'Deze gebruikers werden gedesactiveerd:',
	'LDAP users synchronized.' => 'LDAP gebruikers gesynchroniseerd',
	'Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set.' => 'Synchronisatie van groepen kan niet worden uitgevoerd zonder dat LDAPGroupIdAttribute en/of LDAPGroupNameAttribute ingesteld zijn.',
	'LDAP groups synchronized with existing groups.' => 'LDAP groepen zijn gesynchroniseerd met bestaande groepen.',
	'Information about the following groups was modified:' => 'Informatie over volgend groepen werd bijgewerkt:',
	'No LDAP group was found using the filter provided.' => 'Geen LDAP groep gevonden met de opgegeven filter.',
	'The filter used to search for groups was: \'[_1]\'. Search base was: \'[_2]\'' => 'De filter die gebruikt werd om groepen te zoeken was: \'[_1]\'.  Zoekbasis was: \'[_1]\'.',
	'(none)' => '(Geen)',
	'The following groups were deleted:' => 'Volgende groepen werden verwijderd:',
	'Failed to create a new group: [_1]' => 'Nieuwe groep aanmaken mislukt: [_1]',
	'[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.' => '´[_1] directief moet ingesteld zijn om leden van een LDAP groep te synchroniseren naar Movable Type Advanced',
	'Members removed: ' => 'Leden verwijderd:',
	'Members added: ' => 'Leden toegevoegd:',
	'Memberships in the group \'[_2]\' (#[_3]) were changed as a result of synchronizing with the external directory.' => 'Lidmaatschappen in de groep \'[_2]\' (#[_3]) werden aangepast als resultaat van de synchronisatie met de externe directory',
	'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.' => 'LDAPUserGroupMemberAttribute moet ingesteld zijn om synchronisatie van groepsleden mogelijk te maken.',

## addons/Enterprise.pack/lib/MT/Enterprise/Author.pm
	'Loading MT::LDAP failed: [_1].' => 'Laden van MT::LDAP mislukt: [_1]',

## addons/Enterprise.pack/lib/MT/Enterprise/BulkCreation.pm
	'Formatting error at line [_1]: [_2]' => 'Formatteringsfout op regel [_1]: [_2]',
	'Invalid command: [_1]' => 'Ongeldig commando: [_1]',
	'Invalid number of columns for [_1]' => 'Ongeldig aantal kolommen voor [_1]',
	'Invalid user name: [_1]' => 'Ongeldige gebruikersnaam: [_1]',
	'Invalid display name: [_1]' => 'Ongeldige getoonde naam: [_1]',
	'Invalid email address: [_1]' => 'Ongeldig e-mail adres: [_1]',
	'Invalid language: [_1]' => 'Ongeldige taal: [_1]',
	'Invalid password: [_1]' => 'Ongeldig wachtwoord: [_1]',
	'\'Personal Blog Location\' setting is required to create new user blogs.' => '\'Locatie persoonlijke blog\' instelling is vereist om nieuwe gebruikersblogs aan te maken.',
	'Invalid weblog name: [_1]' => 'Ongeldige weblognaam: [_1]',
	'Invalid blog URL: [_1]' => 'Ongeldige blog URL: [_1]',
	'Invalid site root: [_1]' => 'Ongeldige siteroot: [_1]',
	'Invalid timezone: [_1]' => 'Ongeldige tijdzone: [_1]',
	'Invalid theme ID: [_1]' => 'Ongeldig thema ID: [_1]',
	'A theme \'[_1]\' was not found.' => 'Geen \'[_1]\'thema gevonden.', # Translate - New
	'A user with the same name was found.  The registration was not processed: [_1]' => 'Een gebruiker met dezelfde naam werd gevonden.  De registratie werd niet uitgevoerd: [_1]',
	'Blog for user \'[_1]\' can not be created.' => 'Blog voor gebruiker \'[_1]\' kon niet worden aangemaakt.',
	'Blog \'[_1]\' for user \'[_2]\' has been created.' => 'Blog \'[_1]\' voor gebruiker \'[_2]\' werd aangemaakt.',
	'Error assigning weblog administration rights to user \'[_1] (ID: [_2])\' for weblog \'[_3] (ID: [_4])\'. No suitable weblog administrator role was found.' => 'Fout bij toekennen ven weblog administratierechten aan gebruiker \'[_1] (ID: [_2])\' voor weblog \'[_3] (ID: [_4])\'.  Er werd geen geschikte administrator rol gevonden in het systeem.',
	'Permission granted to user \'[_1]\'' => 'Permissie toegekend aan gebruiker \{[_1]\'',
	'User \'[_1]\' already exists. The update was not processed: [_2]' => 'Gebruiker  \'[_1]\' bestaat al.  De update werd niet doorgevoerd: [_2]',
	'User \'[_1]\' not found.  The update was not processed.' => 'Gebruiker  \'[_1]\' niet gevonden.  De update werd niet doorgevoerd.',
	'User \'[_1]\' has been updated.' => 'Gebruiker \'[_1]\' is bijgewerkt.',
	'User \'[_1]\' was found, but the deletion was not processed' => 'Gebruiker  \'[_1]\' werd gevonden maar de verwijdering werd niet uitgevoerd.',
	'User \'[_1]\' not found.  The deletion was not processed.' => 'Gebruiker  \'[_1]\' werd niet gevonden.  De verwijdering werd niet uitgevoerd.',
	'User \'[_1]\' has been deleted.' => 'Gebruiker \'[_1]\' werd verwijderd.',

## addons/Enterprise.pack/lib/MT/Enterprise/CMS.pm
	'Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding.' => 'Movable Type Advanced probeerde net uw account uit te schakelen tijdens synchronisatie met de externe directory.  Er moet een fout zitten in de instellingen voor extern gebruikersbeheer.  Gelieve uw configuratie bij te stellen voor u verder gaat.',
	'Each group must have a name.' => 'Elke groep moet een naam hebben',
	'Search Users' => 'Gebruikers zoeken',
	'Select Groups' => 'Selecteer groepen',
	'Groups Selected' => 'Geselecteerde groepen',
	'Search Groups' => 'Groepen zoeken',
	'Add Users to Groups' => 'Gebruikers toevoegen aan groepen',
	'Invalid group' => 'Ongeldige groep',
	'Add Users to Group [_1]' => 'Voeg gebruikers toe aan groep [_1]',
	'User \'[_1]\' (ID:[_2]) removed from group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Gebruiker \'[_1]\' (ID:[_2]) verwijderd uit groep \'[_3]\' (ID:[_4]) door \'[_5]\'',
	'Group load failed: [_1]' => 'Laden groep mislukt: [_1]',
	'User load failed: [_1]' => 'Laden gebruiker mislukt: [_1]',
	'User \'[_1]\' (ID:[_2]) was added to group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Gebruiker \'[_1]\' (ID:[_2]) toegevoegd aan groep \'[_3]\' (ID:[_4]) door \'[_5]\'',
	'Users & Groups' => 'Gebruikers & Groepen',
	'Group Profile' => 'Groepsprofiel',
	'Author load failed: [_1]' => 'Laden auteur mislukt: [_1]',
	'Invalid user' => 'Ongeldige gebruiker',
	'Assign User [_1] to Groups' => 'Gebruiker [_1] toewijzen aan groepen',
	'Type a group name to filter the choices below.' => 'Tik een groepsnaam in om de onderstaande keuzes te filteren',
	'Bulk import cannot be used under external user management.' => 'Bulk import kan niet worden gebruikt onder extern gebruikersbeheer.',
	'Bulk management' => 'Bulkbeheer',
	'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.' => 'Er werden geen records gevonden in het bestand.  Kijk na of het bestand CRLF gebruiker als einde-regel karakters.',
	'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].' => '[quant,_1,Gebruiker,Gebruikers] geregistreerd, [quant,_2,gebruiker,gebruikers] bijgewerkt, [quant,_3,gebruiker,gebruikers] verwijderd.',
	'Bulk author export cannot be used under external user management.' => 'Bulk export van auteurs kan niet gebruikt worden onder extern gebruikersbeheer.',
	'A user cannot change his/her own username in this environment.' => 'Een gebruiker kan zijn/haar gebruikersnaam niet aanpassen in deze omgeving',
	'An error occurred when enabling this user.' => 'Er deed zich een fout voor bij het activeren van deze gebruiker.',

## addons/Enterprise.pack/lib/MT/Enterprise/Upgrade.pm
	'Fixing binary data for Microsoft SQL Server storage...' => 'Binaire data aan het fixen voor opslag in Microsoft SQL Server...',

## addons/Enterprise.pack/lib/MT/Enterprise/Wizard.pm
	'PLAIN' => 'PLAIN',
	'CRAM-MD5' => 'CRAM-MD5',
	'Digest-MD5' => 'Digest-MD5',
	'Login' => 'Login',
	'Found' => 'Gevonden',
	'Not Found' => 'Niet gevonden',

## addons/Enterprise.pack/lib/MT/Group.pm

## addons/Enterprise.pack/lib/MT/LDAP.pm
	'Invalid LDAPAuthURL scheme: [_1].' => 'Ongeldig LDAPAuthURL schema: [_1].',
	'Error connecting to LDAP server [_1]: [_2]' => 'Probleem bij connecteren naar LDAP server [_1]: [_2]',
	'User not found in LDAP: [_1]' => 'Gebruiker niet gevonden in LDAP: [_1]',
	'Binding to LDAP server failed: [_1]' => 'Binden aan LDAP server mislukt: [_1]',
	'More than one user with the same name found in LDAP: [_1]' => 'Meer dan één gebruiker met dezelfde naam gevonden in LDAP: [_1]',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/MSSQLServer.pm
	'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.' => 'PublishCharset [_1] wordt niet ondersteund in deze versie van de MS SQL Server Driver',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/UMSSQLServer.pm
	'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.' => 'Deze versie van de UMSSQLServer driver vereist DBD::ODBC versie 1.14.',
	'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.' => 'Deze verie van de UMSSQLServer driver vereist DBD::ODBC gecompileerd met Unicode ondersteuning.',

## addons/Enterprise.pack/tmpl/author_bulk.tmpl
	'Manage Users in bulk' => 'Gebruikers beheren in bulk',
	'_USAGE_AUTHORS_2' => 'U kunt gebruikers aanmaken, bewerken en verwijderen in bulk door een CSV-geformatteerd bestand te uploaden dat de juiste instructies en relevante gegevens bevat.',
	q{New user blog would be created on '[_1]'.} => q{Nieuwe gebruikersblog zou aangemaakt worden onder '[_1]'.},
	'[_1] Edit</a>' => '[_1] bewerken</a>',
	q{You must set 'Personal Blog Location' to create a new blog for each new user.} => q{U moet de 'Persoonlijke blog locatie' instellen om een nieuwe blog aan te maken voor elke nieuwe gebruiker.},
	'[_1] Setting</a>' => '[_1] instelling</a>',
	'Upload source file' => 'Bronbestand uploaden',
	'Specify the CSV-formatted source file for upload' => 'Geef het CSV-geformatteerde bronbestand op dat moet worden geupload',
	'Source File Encoding' => 'Encodering bronbestand',
	'Movable Type will automatically try to detect the character encoding of your import file.  However, if you experience difficulties, you can set the character encoding explicitly.' => 'Movable Type zal proberen automatisch de encodering van uw importbestand te detecteren.  Als u echter fouten opmerkt of problemen ondervindt, kunt u de karacterencodering ook expliciet instellen.',
	'Upload (u)' => 'Uploaden (u)',

## addons/Enterprise.pack/tmpl/cfg_ldap.tmpl
	'Authentication Configuration' => 'Authenticatieconfiguratie',
	'You must set your Authentication URL.' => 'U moet uw AuthenticatieURL instellen.',
	'You must set your Group search base.' => 'U moet uw Group search base instellen.',
	'You must set your UserID attribute.' => 'U moet uw UserID attribuut instellen.',
	'You must set your email attribute.' => 'U moet uw email attribuut instellen.',
	'You must set your user fullname attribute.' => 'U moet uw user fullname attribuut instellen.',
	'You must set your user member attribute.' => 'U moet uw user member attribuut instellen.',
	'You must set your GroupID attribute.' => 'U moet uw GroupID attribuut instellen.',
	'You must set your group name attribute.' => 'U moet uw group name attribuut instellen.',
	'You must set your group fullname attribute.' => 'U moet uw fullname attribuut instellen.',
	'You must set your group member attribute.' => 'U moet uw group member attribuut instellen.',
	'An error occurred while attempting to connect to the LDAP server: ' => 'Er deed zich een fout voor bij het verbinden met de LDAP server: ',
	'You can configure your LDAP settings from here if you would like to use LDAP-based authentication.' => 'U kunt uw LDAP instellingen van hieruit configureren als uw LDAP-gebaseerde authenticatie wenst te gebruiken.',
	'Your configuration was successful.' => 'Configuratie is geslaagd.',
	q{Click 'Continue' below to configure the External User Management settings.} => q{Klik hieronder op 'Doorgaan' om de instellingen voor extern gebruikersbeheer te configureren.},
	q{Click 'Continue' below to configure your LDAP attribute mappings.} => q{Klik hieronder op 'Doorgaan' om uw LDAP attribute mappings in te stellen.},
	'Your LDAP configuration is complete.' => 'Uw LDAP configuratie is voltooid.',
	q{To finish with the configuration wizard, press 'Continue' below.} => q{Om naar het einde van de configuratiewizard te gaan, klik hieronder op 'Doorgaan'.},
	'Cannot locate Net::LDAP. Net::LDAP module is required to use LDAP authentication.' => 'Kan Net:LDAP niet vinden. Net::LDAP is vereist om LDAP authenticatie te kunnen gebruiken.',
	'Use LDAP' => 'LDAP gebruiken',
	'Authentication URL' => 'Authenticatie URL',
	'The URL to access for LDAP authentication.' => 'De URL te gebruiken om toegang te krijgen tot LDAP authenticatie',
	'Authentication DN' => 'Authenticatie DN',
	'An optional DN used to bind to the LDAP directory when searching for a user.' => 'Een optionele DN die wordt gebruikt om aan de LDAP directory te binden wanneer er naar een gebruiker wordt gezocht.',
	'Authentication password' => 'Authenticatiewachtwoord',
	'Used for setting the password of the LDAP DN.' => 'Gebruikt om het wachtwoord in te stellen van de LDAP DN',
	'SASL Mechanism' => 'SASL mechanisme',
	'The name of the SASL Mechanism used for both binding and authentication.' => 'De naam van het SASL Mechanisme gebruikt voor binding en authenticatie.',
	'Test Username' => 'Test gebruikersnaam',
	'Test Password' => 'Test wachtwoord',
	'Enable External User Management' => 'Extern gebruikersbeheer inschakelen',
	'Synchronization Frequency' => 'Synchronisatiefrequentie',
	'The frequency of synchronization in minutes. (Default is 60 minutes)' => 'Synchronisatiefrequentie in minuten. (Standaard is 60 minuten)',
	'15 Minutes' => '15 minuten',
	'30 Minutes' => '30 minuten',
	'60 Minutes' => '60 minuten',
	'90 Minutes' => '90 minuten',
	'Group Search Base Attribute' => 'Group search basisattribuut',
	'Group Filter Attribute' => 'Group filter attribuut',
	'Search Results (max 10 entries)' => 'Zoekresultaten (max. 10 items)',
	'CN' => 'CN',
	'No groups were found with these settings.' => 'Er werden geen groepen gevonden met deze instellingen',
	'Attribute mapping' => 'Attribuutmapping',
	'LDAP Server' => 'LDAP server',
	'Other' => 'Andere',
	'User ID Attribute' => 'User ID attribuut',
	'Email Attribute' => 'Email attribuut',
	'User Fullname Attribute' => 'User fullname attribuut',
	'User Member Attribute' => 'User member attribuut',
	'GroupID Attribute' => 'GroupID attribuut',
	'Group Name Attribute' => 'Group name attribuut',
	'Group Fullname Attribute' => 'Group fullname attribuut',
	'Group Member Attribute' => 'Group member attribuut',
	'Search Result (max 10 entries)' => 'Zoekresultaat (max. 10 items)',
	'Group Fullname' => 'Volledige naam groep',
	'(and [_1] more members)' => '(en nog [_1] leden)',
	'No groups could be found.' => 'Er werden geen groepen gevonden',
	'User Fullname' => 'Volledige naam gebruiker',
	'(and [_1] more groups)' => '(en nog [_1] groepen)',
	'No users could be found.' => 'Er werden geen gebruikers gevonden',
	'Test connection to LDAP' => 'Verbinding met LDAP testen',
	'Test search' => 'Zoektest',

## addons/Enterprise.pack/tmpl/create_author_bulk_end.tmpl
	'All users were updated successfully.' => 'Alle gebruikers met succes bijgewerkt.',
	'An error occurred during the update process. Please check your CSV file.' => 'Er deed zich een fout voor tijdens het updateproces.  Gelieve uw CSV bestand na te kijken.',

## addons/Enterprise.pack/tmpl/create_author_bulk_start.tmpl

## addons/Enterprise.pack/tmpl/dialog/dialog_select_group_user.tmpl

## addons/Enterprise.pack/tmpl/dialog/select_groups.tmpl
	'You need to create some groups.' => 'U moet een paar groepen aanmaken.',
	q{Before you can do this, you need to create some groups. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Click here</a> to create a group.} => q{Voor u dit kunt doen, moet u eerst een paar groepen aanmaken. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Klik hier</a> om een groep aan te maken.},

## addons/Enterprise.pack/tmpl/edit_group.tmpl
	'Edit Group' => 'Groep bewerken',
	'Create Group' => 'Groep aanmaken',
	'This group profile has been updated.' => 'Dit groepsprofiel werd bijgewerkt.',
	'This group was classified as pending.' => 'Deze groep werd geclassificeerd als in aanvraag.',
	'This group was classified as disabled.' => 'Deze groep werd geclassificeerd als gedeactiveerd.',
	'Member ([_1])' => 'Lid ([_1])',
	'Members ([_1])' => 'Leden ([_1])',
	'Permission ([_1])' => 'Permissie ([_1])',
	'Permissions ([_1])' => 'Permissies ([_1])',
	'LDAP Group ID' => 'LDAP Group ID',
	'The LDAP directory ID for this group.' => 'Het LDAP directory ID van deze groep',
	'Status of this group in the system. Disabling a group prohibits its members&rsquo; from accessing the system but preserves their content and history.' => 'Status van deze groep in het systeem.  Een groep deactiveren ontzegt de leden ervan toegang tot het systeem maar behoudt hun inhoud en geschiedenis.',
	'The name used for identifying this group.' => 'De naam gebruikt om deze groep mee aan te duiden.',
	'The display name for this group.' => 'De getoonde naam van deze groep.',
	'The description for this group.' => 'De beschrijving van deze groep.',
	'Save changes to this field (s)' => 'De wijzigingen aan dit veld opslaan (s)',

## addons/Enterprise.pack/tmpl/include/group_table.tmpl
	'Enable selected group (e)' => 'De geselecteerde groep activeren (e)',
	'Disable selected group (d)' => 'De geselecteerde groep deactiveren (d)',
	'group' => 'groep',
	'groups' => 'groepen',
	'Remove selected group (d)' => 'De geselecteerde groep verwijderen (d)',

## addons/Enterprise.pack/tmpl/include/list_associations/page_title.group.tmpl
	'Users &amp; Groups for [_1]' => 'Gebruikers &amp; groepen voor [_1]',

## addons/Enterprise.pack/tmpl/listing/group_list_header.tmpl
	'You successfully disabled the selected group(s).' => 'U deactiveerde met succes de geselecteerde groep(en).',
	'You successfully enabled the selected group(s).' => 'U activeerde met succes de geselecteerde groep(en).',
	'You successfully deleted the groups from the Movable Type system.' => 'U verwijderde met succes de groepen uit het Movable Type systeem.',
	q{You successfully synchronized the groups' information with the external directory.} => q{U synchroniseerde met succes de groepsinformatie met de externe directory.},

## addons/Enterprise.pack/tmpl/listing/group_member_list_header.tmpl
	'You successfully deleted the users.' => 'U verwijderde met succes de gebruikers.',
	'You successfully added new users to this group.' => 'U voegde met succes nieuwe gebruikers toe aan deze groep.',
	q{You successfully synchronized users' information with the external directory.} => q{U synchroniseerde met succes informatie over gebruikers met de externe directory.},
	'Some ([_1]) of the selected users could not be re-enabled because they are no longer found in LDAP.' => 'Sommige ([_1]) van de geselecteerde gebruikers konden niet gereactiveerd worden omdat ze niet langer gevonden worden in LDAP.',
	'You successfully removed the users from this group.' => 'U verwijderde met succes de gebruikers uit de groep.',

);

1;
