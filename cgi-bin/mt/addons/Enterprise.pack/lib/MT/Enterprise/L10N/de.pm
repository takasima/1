# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::L10N::de;

use strict;
use base 'MT::Enterprise::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Enterprise.pack/app-cms.yaml
	'Groups ([_1])' => 'Gruppen ([_1])',
	'Are you sure you want to delete the selected group(s)?' => 'Gewählte Gruppe(n) wirklich löschen?',
	'Are you sure you want to remove the selected member(s) from the group?' => 'Gewählte(n) Benutzer wirklich aus Gruppe entfernen?',
	'[_1]\'s Group' => 'Gruppen von [_1]', # Translate - New # OK
	'Groups' => 'Gruppen',
	'Manage Member' => 'Mitglieder verwalten',
	'Bulk Author Export' => 'Stapelexport von Autoren',
	'Bulk Author Import' => 'Stapelimport von Autoren',
	'Synchronize Users' => 'Benutzer synchronisieren',
	'Synchronize Groups' => 'Gruppen synchronisieren',
	'Add user to group' => 'Benutzer zu Gruppe hinzufügen',

## addons/Enterprise.pack/app-wizard.yaml
	'This module is required in order to use the LDAP Authentication.' => 'Dieses Modul ist zur Nutzung der LDAP-Authentifizierung erforderlich.',
	'This module is required in order to use SSL/TLS connection with the LDAP Authentication.' => 'Dieses Modul ist zur Nutzung von SSL/TLS-Verbindungen bei der LDAP-Authentifizierung erforderlich.',
	'This module and its dependencies are required in order to use CRAM-MD5, DIGEST-MD5 or LOGIN as a SASL mechanism.' => 'Dieses Modul und seine Abhängigkeiten sind zur Verwendung von CRAM-MD5, DIGEST-MD5 oder LOGIN als SASL-Mechanismus erforderlich.',

## addons/Enterprise.pack/config.yaml
	'Permissions of group: [_1]' => 'Gruppen-Berechtigungen: [_1]',
	'Group' => 'Gruppe',
	'Groups associated with author: [_1]' => 'Mit Autor verknüpfte Gruppen: [_1]',
	'Inactive' => 'Inaktiv',
	'Members of group: [_1]' => 'Gruppenmitglieder: [_1]',
	'Advanced Pack' => 'Advanced-Pack',
	'User/Group' => 'Benutzer/Gruppe',
	'User/Group Name' => 'Benutzer-/Gruppen-Name',
	'__GROUP_MEMBER_COUNT' => 'Mitglieder',
	'My Groups' => 'Meine Gruppen',
	'Group Name' => 'Gruppenname',
	'Manage Group Members' => 'Gruppenmitglieder verwalten',
	'Group Members' => 'Gruppenmitglieder',
	'Group Member' => 'Groupmember',
	'Permissions for Users' => 'Benutzer-Berechtigungen',
	'Permissions for Groups' => 'Gruppen-Berechtigungen',
	'Active Groups' => 'Aktive Gruppen',
	'Disabled Groups' => 'Deaktivierte Gruppen',
	'Oracle Database (Recommended)' => 'Oracle-Datenbank (empfohlen)',
	'Microsoft SQL Server Database' => 'Microsoft SQL Server-Datenbank',
	'Microsoft SQL Server Database UTF-8 support (Recommended)' => 'Microsoft SQL Server-Datenbank mit UTF-8-Unterstützung (empfohlen)',
	'Publish Charset' => 'Zeichenkodierung',
	'ODBC Driver' => 'ODBC-Treiber',
	'External Directory Synchronization' => 'Synchronisierung mit externem Verzeichnis',
	'Populating author\'s external ID to have lower case user name...' => 'Setze externe Benutzerkennung für kleingeschriebene Benutzernamen...',

## addons/Enterprise.pack/lib/MT/Auth/LDAP.pm
	'User [_1]([_2]) not found.' => 'Benutzerkonto [_1]([_2]) nicht gefunden.',
	'User \'[_1]\' cannot be updated.' => 'Benutzerkonto \'[_1]\' kann nicht aktualisiert werden.',
	'User \'[_1]\' updated with LDAP login ID.' => 'Benutzerkonto \'[_1]\' mit LDAP-Login-ID aktualisiert.',
	'LDAP user [_1] not found.' => 'LDAP-Benutzerkonto [_1] nicht gefunden.',
	'User [_1] cannot be updated.' => 'Benutzerkonto [_1] kann nicht aktualisiert werden.',
	'User cannot be updated: [_1].' => 'Benutzerkonto kann nicht aktualisiert werden: [_1].',
	'Failed login attempt by user \'[_1]\' who was deleted from LDAP.' => 'Fehlgeschlagener Anmeldeversuch von aus LDAP gelöschtem Benutzer \'[_1]\'.',
	'User \'[_1]\' updated with LDAP login name \'[_2]\'.' => 'Benutzerkonto \'[_1]\' mit LDAP-Login-Name aktualisiert.',
	'Failed login attempt by user \'[_1]\'. A user with that username already exists in the system with a different UUID.' => 'Fehlgeschlagener Anmeldeversuch von Benutzer \'[_1]\'. Es ist weiterer Benutzer mit gleichem Benutzernamen, aber anderer UUID im System vorhanden.',
	'User \'[_1]\' account is disabled.' => 'Benutzerkonto \'[_1]\' ist deaktiviert.',
	'LDAP users synchronization interrupted.' => 'LDAP-Benutzersynchronisierung unterbrochen.',
	'Loading MT::LDAP failed: [_1]' => 'Beim Laden von MT::LDAP ist ein Fehler aufgetreten: [_1]',
	'External user synchronization failed.' => 'Synchronisierung externer Benutzer fehlgeschlagen.',
	'An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted.' => 'Es wurde versucht, alle Administratorenkonten zu deaktivieren. Synchronisation unterbrochen.',
	'Information about the following users was modified:' => 'Folgende Benutzerkonten wurden bearbeitet:',
	'The following users were disabled:' => 'Folgende Benutzerkonten wurden deaktiviert:',
	'LDAP users synchronized.' => 'LDAP-Benutzer synchronisiert.',
	'Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set.' => 'Zur Synchronisierung von Gruppen muss LDAPGroupIDAttribute und/oder LDAPGroupNameAttribute gesetzt sein.',
	'LDAP groups synchronized with existing groups.' => 'LDAP-Gruppen mit vorhandenen Gruppen sychnronisiert.',
	'Information about the following groups was modified:' => 'Folgende Gruppen wuirden bearbeitet:',
	'No LDAP group was found using the filter provided.' => 'Keine LDAP-Gruppe mit dem angegebenen Filter gefunden.',
	'The filter used to search for groups was: \'[_1]\'. Search base was: \'[_2]\'' => 'Für die Gruppensuche verwendeter Filter: \'[_1]\'. Suchbasis: \'[_2]\'',
	'(none)' => '(Keine)',
	'The following groups were deleted:' => 'Die folgenden Gruppen wurden gelöscht:',
	'Failed to create a new group: [_1]' => 'Fehler beim Anlegen einer neuen Gruppe: [_1]',
	'[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.' => '[_1]-Direktive muss gesetzt sein, um LDAP-Gruppenmitgliedschaften mit Movable Type Advanced zu synchronisieren.',
	'Members removed: ' => 'Entfernte Mitglieder:',
	'Members added: ' => 'Hinzugefügte Mitglieder:',
	'Memberships in the group \'[_2]\' (#[_3]) were changed as a result of synchronizing with the external directory.' => 'Mitgliedschaften der Gruppe \'[_2]\' (#[_3]) wurden durch die Synchronisierung mit dem externen Verzeichnis verändert.',
	'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.' => 'Zur Synchronisierung von Gruppen muss LDAPUserGroupMemberAttribute gesetzt sein.',

## addons/Enterprise.pack/lib/MT/Enterprise/Author.pm
	'Loading MT::LDAP failed: [_1].' => 'MT::LDAP konnte nicht geladen werden: [_1]',

## addons/Enterprise.pack/lib/MT/Enterprise/BulkCreation.pm
	'Formatting error at line [_1]: [_2]' => 'Formatierungsfehler in Zeile [_1]: [_2]',
	'Invalid command: [_1]' => 'Unbekannter Befehl: [_1]',
	'Invalid number of columns for [_1]' => 'Ungültige Spaltenzahl für [_1]',
	'Invalid user name: [_1]' => 'Ungültiger Benutzername: [_1]',
	'Invalid display name: [_1]' => 'Ungültiger Anzeigename: [_1]',
	'Invalid email address: [_1]' => 'Ungültige E-Mail-Adresse: [_1]',
	'Invalid language: [_1]' => 'Ungültige Sprache: [_1]',
	'Invalid password: [_1]' => 'Ungültiges Passwort: [_1]',
	'\'Personal Blog Location\' setting is required to create new user blogs.' => 'Zum Anlegen neuer Benutzerblogs muss in den Einstellungen deren Speicherort angegeben sein.',
	'Invalid weblog name: [_1]' => 'Ungültiger Weblogname: [_1]',
	'Invalid blog URL: [_1]' => 'Ungültige Blog-URL: [_1]',
	'Invalid site root: [_1]' => 'Ungültiges Wurzelverzeichnis: [_1]',
	'Invalid timezone: [_1]' => 'Ungültige Zeitzone: [_1]',
	'Invalid theme ID: [_1]' => 'Ungültige Themen-ID: [_1]',
	'A user with the same name was found.  The registration was not processed: [_1]' => 'Benutzer mit gleichem Namen gefunden und Konto daher nicht angelegt: [_1]',
	'Blog for user \'[_1]\' can not be created.' => 'Blog für Benutzer \'[_1]\' kann nicht angelegt werden.',
	'Blog \'[_1]\' for user \'[_2]\' has been created.' => 'Blog \'[_1]\' für Benutzer \'[_2]\' angelegt.',
	'Error assigning weblog administration rights to user \'[_1] (ID: [_2])\' for weblog \'[_3] (ID: [_4])\'. No suitable weblog administrator role was found.' => 'Fehler bei der Zuweisung von Blog-Administrationsrechten für Blog \'[_3] (ID: [_4])\' an Benutzer \'[_1] (ID: [_2])\'. Keine geeignete Administratorenrolle gefunden.',
	'Permission granted to user \'[_1]\'' => 'Berechtigungenga an Benutzer \'[_1]\' vergeben',
	'User \'[_1]\' already exists. The update was not processed: [_2]' => 'Benutzer \'[_1]\' bereits vorhanden, Konto daher nicht aktualisiert: [_2]',
	'User \'[_1]\' not found.  The update was not processed.' => 'Benutzer \'[_1]\' nicht gefunden, Konto daher nicht aktualisiert.',
	'User \'[_1]\' has been updated.' => 'Benutzerkonto \'[_1]\' aktualisiert.',
	'User \'[_1]\' was found, but the deletion was not processed' => 'Benutzer \'[_1]\' gefunden, Konto aber nicht gelöscht',
	'User \'[_1]\' not found.  The deletion was not processed.' => 'Benutzer \'[_1]\' nicht gefunden, Konto daher nicht gelöscht',
	'User \'[_1]\' has been deleted.' => 'Benutzerkonto \'[_1]\' gelöscht.',

## addons/Enterprise.pack/lib/MT/Enterprise/CMS.pm
	'Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding.' => 'Movable Type Advanced hat während der Synchronisation versucht, Ihr Benutzerkonto zu deaktivieren. Das deutet auf einen Fehler in der externen Benutzerverwaltung hin. Überprüfen Sie daher die dortigen Einstellungen, bevor Sie Ihre Arbeit in Movable Type forsetzen.',
	'Each group must have a name.' => 'Jede Gruppe muss einen eigenen Namen haben.',
	'Search Users' => 'Benutzer suchen',
	'Select Groups' => 'Gruppen auswählen',
	'Groups Selected' => 'Gewählte Gruppen',
	'Search Groups' => 'Gruppen suchen',
	'Add Users to Groups' => 'Benutzer zu Gruppen hinzufügen',
	'Invalid group' => 'Ungültige Gruppe',
	'Add Users to Group [_1]' => 'Benutzer zu Gruppe [_1] hinzufügen',
	'User \'[_1]\' (ID:[_2]) removed from group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Benutzer \'[_1]\' (ID:[_2]) von \'[_5]\' aus Gruppe \'[_3]\' (ID:[_4]) entfernt',
	'Group load failed: [_1]' => 'Fehler beim Laden einer Gruppe:',
	'User load failed: [_1]' => 'Fehler beim Laden eines Benutzers:',
	'User \'[_1]\' (ID:[_2]) was added to group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Benutzer \'[_1]\' (ID:[_2]) von \'[_5]\' zu Gruppe \'[_3]\' (ID:[_4]) hinzugefügt',
	'Users & Groups' => 'Benutzer und Gruppen',
	'Group Profile' => 'Gruppenprofile',
	'Author load failed: [_1]' => 'Fehler beim Laden eines Autoren: [_1]',
	'Invalid user' => 'Ungültiger Benutzer',
	'Assign User [_1] to Groups' => 'Gruppen an Benutzer [_1] zuweisen',
	'Type a group name to filter the choices below.' => 'Geben Sie einen Gruppennamen ein, um die Auswahl einzuschränken.',
	'Bulk import cannot be used under external user management.' => 'Stapelimport ist bei externer Benutzerverwaltung nicht möglich.',
	'Bulk management' => 'Stapelverwaltung',
	'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.' => 'Keine Einträge in Datei gefunden. Bitte stellen Sie sicher, daß für die Zeilenenden CRLF verwendet wird.',
	'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].' => '[quant,_1,Benutzer] registiert, [quant,_2,Benutzerkonto,Benutzerkonten] aktualisiert, [quant,_3,Benutzerkonto,Benutzerkonten] gelöscht.',
	'Bulk author export cannot be used under external user management.' => 'Stapelexport von Benutzerkonten bei externer Benutzerverwaltung nicht möglich.',
	'A user can\'t change his/her own username in this environment.' => 'Benutzer können ihre eigenen Benutzernamen in diesem Kontext nicht ändern.',
	'An error occurred when enabling this user.' => 'Bei der Aktivierung dieses Benutzerkontos ist ein Fehler aufgetreten',

## addons/Enterprise.pack/lib/MT/Enterprise/Upgrade.pm
	'Fixing binary data for Microsoft SQL Server storage...' => 'Bereite Binärdaten zur Speicherung in Microsoft SQL Server vor...',

## addons/Enterprise.pack/lib/MT/Enterprise/Wizard.pm
	'PLAIN' => 'PLAIN',
	'CRAM-MD5' => 'CRAM-MD5',
	'Digest-MD5' => 'Digest-MD5',
	'Login' => 'Login',
	'Found' => 'Gefunden',
	'Not Found' => 'Nicht gefunden',

## addons/Enterprise.pack/lib/MT/Group.pm

## addons/Enterprise.pack/lib/MT/LDAP.pm
	'Invalid LDAPAuthURL scheme: [_1].' => 'Ungültiges LDAPAuthURL-Schema: [_1].',
	'Error connecting to LDAP server [_1]: [_2]' => 'Verbindung zu LDAP-Server [_1] fehlgeschlagen: [_2]',
	'User not found in LDAP: [_1]' => 'Benutzer nicht im LDAP-Verzeichnis gefunden: [_1]',
	'Binding to LDAP server failed: [_1]' => 'Bindung an LDAP-Server fehlgeschlagen: [_1]',
	'More than one user with the same name found in LDAP: [_1]' => 'Mehrere Benutzer mit dem gleichen Namen im LDAP-Verzeichnis gefunden: [_1]',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/MSSQLServer.pm
	'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.' => 'PublishCharset [_1] wird von dieser Version des MS SQL Server-Treibers nicht unterstützt.',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/UMSSQLServer.pm
	'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.' => 'Diese Version des UMSSQLServer-Treibers erfordert DBD::ODBC in der Version 1.14.',
	'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.' => 'Diese Version des UMSSQLServer-Treiber erfodert ein mit Unicode-Unterstützung compiliertes DBD::ODBC.',

## addons/Enterprise.pack/tmpl/author_bulk.tmpl
	'Manage Users in bulk' => 'Benutzerverwaltung im Stapel',
	'_USAGE_AUTHORS_2' => 'Sie können Benutzerkonto im Stapel anlegen, bearbeiten und löschen, indem Sie CSV-formatierte Steuerungsdatei mit den entsprechenden Daten und Befehlen hochladen.',
	q{New user blog would be created on '[_1]'.} => q{Neue Benutzerblogs werden auf '[_1]' angelegt.},
	'[_1] Edit</a>' => '[_1] bearbeiten</a>',
	q{You must set 'Personal Blog Location' to create a new blog for each new user.} => q{Um für neue Benutzer automatisch neue Blogs anzulegen, legen Sie bitte deren Speicherort fest.},
	'[_1] Setting</a>' => '[_1]-Einstellungen</a>',
	'Upload source file' => 'Quelldatei hochladen',
	'Specify the CSV-formatted source file for upload' => 'Geben Sie die hochzuladende CSV-Quelldatei an',
	'Source File Encoding' => 'Zeichenkodierung der Quelldatei',
	'Movable Type will automatically try to detect the character encoding of your import file.  However, if you experience difficulties, you can set the character encoding explicitly.' => 'Movable Type versucht automatisch die Zeichenkodierung Ihrer Importdatei zu ermitteln. Sie können die Kodierung aber auch selbst angeben.',
	'Upload (u)' => 'Hochladen (u)',

## addons/Enterprise.pack/tmpl/cfg_ldap.tmpl
	'Authentication Configuration' => 'Authentifizierungs- Einstellungen',
	'You must set your Authentication URL.' => 'Authentifizierungs-URL erforderlich',
	'You must set your Group search base.' => 'Groupsearchbase-Attribut erforderlich',
	'You must set your UserID attribute.' => 'UserID-Attribut erforderlich',
	'You must set your email attribute.' => 'Email-Attribut erforderlich',
	'You must set your user fullname attribute.' => 'Userfullname-Attribut erforderlich',
	'You must set your user member attribute.' => 'Usermember-Attribut erforderlich',
	'You must set your GroupID attribute.' => 'GroupID-Attribut erforderlich',
	'You must set your group name attribute.' => 'Groupname-Attribut erforderlich',
	'You must set your group fullname attribute.' => 'Groupfullname-Attribut erforderlich',
	'You must set your group member attribute.' => 'Groupmember-Attribut erforderlich',
	'An error occurred while attempting to connect to the LDAP server: ' => 'Es konnte keine Verbindung zum LDAP-Server aufgebaut werden: ',
	'You can configure your LDAP settings from here if you would like to use LDAP-based authentication.' => 'Wenn Sie LDAP-Authentifizierung verwenden möchten, können Sie hier die entsprechenden Einstellungen vornehmen.',
	'Your configuration was successful.' => 'Konfigurierung erfolgreich.',
	q{Click 'Continue' below to configure the External User Management settings.} => q{Klicken Sie auf 'Weiter', um die externe Benutzerverwaltung zu konfigurieren.},
	q{Click 'Continue' below to configure your LDAP attribute mappings.} => q{Klicken Sie auf 'Weiter', um die LDAP-Attribute zuzuweisen.},
	'Your LDAP configuration is complete.' => 'Ihre LDAP-Konfigurierung ist abgeschlossen.',
	q{To finish with the configuration wizard, press 'Continue' below.} => q{Mit einem Klick auf 'Weiter' schließen Sie die Konfigurierung ab.},
	q{Can't locate Net::LDAP. Net::LDAP module is required to use LDAP authentication.} => q{Kann Net::LDAP nicht finden. Net::LDAP ist zur Authentifizierung über LDAP erforderlich.},
	'Use LDAP' => 'LDAP verwenden',
	'Authentication URL' => 'Authentifizierungs-URL',
	'The URL to access for LDAP authentication.' => 'Adresse (URL) zur LDAP-Authentifizierung',
	'Authentication DN' => 'Authentifizierungs-DN',
	'An optional DN used to bind to the LDAP directory when searching for a user.' => 'Optionaler DN zur LDAP-Bindung bei der Benutzersuche',
	'Authentication password' => 'Authentifizierungs- Passwort',
	'Used for setting the password of the LDAP DN.' => 'Wird zur Einstellung des LDAP DN-Passworts verwendet',
	'SASL Mechanism' => 'SASL-Mechanismus',
	'The name of the SASL Mechanism used for both binding and authentication.' => 'Name des zur Bindung und zur Authentifizierung verwendeten SASL-Mechanismus',
	'Test Username' => 'Test-Benutzername',
	'Test Password' => 'Test-Passwort',
	'Enable External User Management' => 'Externe Benutzerverwaltung aktivieren',
	'Synchronization Frequency' => 'Aktualisierungsintervall',
	'The frequency of synchronization in minutes. (Default is 60 minutes)' => 'Synchronisierungintervall in Minuten (Standard: alle 60 Minuten)',
	'15 Minutes' => '15 Minuten',
	'30 Minutes' => '30 Minuten',
	'60 Minutes' => '60 Minuten',
	'90 Minutes' => '90 Minuten',
	'Group Search Base Attribute' => 'Groupsearchbase-Attribut',
	'Group Filter Attribute' => 'Groupfilter-Attribut',
	'Search Results (max 10 entries)' => 'Suchergebnis (ersten 10 Treffer)',
	'CN' => 'CN (Common Name)',
	'No groups were found with these settings.' => 'Keine Gruppe mit diesen Einstellungen gefunden.',
	'Attribute mapping' => 'Attributzuordnung',
	'LDAP Server' => 'LDAP-Server',
	'Other' => 'Anderer',
	'User ID Attribute' => 'UserID-Attribut',
	'Email Attribute' => 'Email-Attribut',
	'User Fullname Attribute' => 'Userfullname-Attribut',
	'User Member Attribute' => 'Usermember-Attribut',
	'GroupID Attribute' => 'GroupID-Attribut',
	'Group Name Attribute' => 'Groupname-Attribut',
	'Group Fullname Attribute' => 'Groupfullname-Attribut',
	'Group Member Attribute' => 'Groupmember-Attribut',
	'Search Result (max 10 entries)' => 'Suchergebnis (ersten 10 Treffer)',
	'Group Fullname' => 'Groupfullname',
	'(and [_1] more members)' => '(und [_1] weitere Mitglieder)',
	'No groups could be found.' => 'Keine Gruppen gefunden.',
	'User Fullname' => 'Userfullname',
	'(and [_1] more groups)' => '(und [_1] weitere Gruppen)',
	'No users could be found.' => 'Keine Benutzer gefunden.',
	'Test connection to LDAP' => 'LDAP-Verbindung testen',
	'Test search' => 'Testsuche',

## addons/Enterprise.pack/tmpl/create_author_bulk_end.tmpl
	'All users were updated successfully.' => 'Alle Benutzerkonten erfolgreich aktualisiert.',
	'An error occurred during the update process. Please check your CSV file.' => 'Bei der Aktualisierung ist ein Fehler aufgetreten. Überprüfen Sie die CSV-Datei.',

## addons/Enterprise.pack/tmpl/create_author_bulk_start.tmpl

## addons/Enterprise.pack/tmpl/dialog/dialog_select_group_user.tmpl

## addons/Enterprise.pack/tmpl/dialog/select_groups.tmpl
	'You need to create some groups.' => 'Bitte legen Sie einige Gruppen an.',
	q{Before you can do this, you need to create some groups. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Click here</a> to create a group.} => q{Bitte legen Sie zuerst einige Gruppen an. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Klicken Sie hier </a> um Gruppen anzulegen.},

## addons/Enterprise.pack/tmpl/edit_group.tmpl
	'Edit Group' => 'Gruppe bearbeiten',
	'Create Group' => 'Gruppe anlegen',
	'This group profile has been updated.' => 'Gruppenprofil aktualisiert.',
	'This group was classified as pending.' => 'Gruppe auf wartend gesetzt.',
	'This group was classified as disabled.' => 'Gruppe deaktiviert.',
	'Member ([_1])' => 'Mitglied ([_1])',
	'Members ([_1])' => 'Mitglieder ([_1])',
	'Permission ([_1])' => 'Berechtigung  ([_1])',
	'Permissions ([_1])' => 'Berechtigungen ([_1])',
	'LDAP Group ID' => 'LDAP-Gruppen-ID',
	'The LDAP directory ID for this group.' => 'Die ID dieser Gruppe im LDAP-Verzeichnis',
	'Status of this group in the system. Disabling a group prohibits its members&rsquo; from accessing the system but preserves their content and history.' => 'Systemweiter Gruppenstatus. Die Deaktivierung einer Gruppe entzieht ihren Mitgliedern den Zugang zum System. Inhalte und Nutzungsverläufe der Mitglieder bleiben jedoch erhalten.',
	'The name used for identifying this group.' => 'Der zur Idenfifizierung diesser Gruppe verwendete Name',
	'The display name for this group.' => 'Der Anzeigename dieser Gruppe',
	'The description for this group.' => 'Die Beschreibung dieser Gruppe.',
	'Save changes to this field (s)' => 'Feld-?nderungen speichern (s)',

## addons/Enterprise.pack/tmpl/include/group_table.tmpl
	'Enable selected group (e)' => 'Gew?hlte Gruppe aktivieren (e)',
	'Disable selected group (d)' => 'Gew?hlte Gruppe deaktivieren (d)',
	'group' => 'Gruppe',
	'groups' => 'Gruppen',
	'Remove selected group (d)' => 'Gew?hlte Gruppe entfernen (d)',

## addons/Enterprise.pack/tmpl/include/list_associations/page_title.group.tmpl
	'Users &amp; Groups for [_1]' => 'Benutzer und Gruppen für [_1]',

## addons/Enterprise.pack/tmpl/listing/group_list_header.tmpl
	'You successfully disabled the selected group(s).' => 'Gruppe(n) erfolgreich deaktiviert.',
	'You successfully enabled the selected group(s).' => 'Gruppe(n) erfolgreich aktiviert.',
	'You successfully deleted the groups from the Movable Type system.' => 'Gruppen erfolgreich aus der Movable Type-Installation gelöscht.',
	q{You successfully synchronized the groups' information with the external directory.} => q{Gruppendaten erfolgreich mit externem Verzeichnis synchronisiert.},

## addons/Enterprise.pack/tmpl/listing/group_member_list_header.tmpl
	'You successfully deleted the users.' => 'Benutzerkonten erfolgreich gelöscht.',
	'You successfully added new users to this group.' => 'Benutzer erfolgreich zu Gruppe hinzugefügt.',
	q{You successfully synchronized users' information with the external directory.} => q{Benutzerdaten erfolgreich mit externem Verzeichnis synchronisiert.},
	'Some ([_1]) of the selected users could not be re-enabled because they are no longer found in LDAP.' => 'Einige ([_2]) der Benutzerkonten wurden nicht wieder aktiviert, da sie nicht mehr im LDAP vorhanden sind.',
	'You successfully removed the users from this group.' => 'Benutzer erfolgreich aus Gruppe entfernt.',

);

1;
