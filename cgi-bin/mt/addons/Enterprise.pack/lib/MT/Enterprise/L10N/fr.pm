# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::L10N::fr;

use strict;
use base 'MT::Enterprise::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Enterprise.pack/app-cms.yaml
	'Groups ([_1])' => 'Groupes ([_1])',
	'Are you sure you want to delete the selected group(s)?' => 'Etes-vous sûr de vouloir effacer les groupes sélectionnés ?',
	'Are you sure you want to remove the selected member(s) from the group?' => 'Êtes-vous sûr de vouloir retirer les groupes sélectionnés ?',
	'[_1]\'s Group' => 'Le Groupe de [_1]', # Translate - New
	'Groups' => 'Groupes',
	'Manage Member' => 'Gérer le membre',
	'Bulk Author Export' => 'Export auteurs en masse',
	'Bulk Author Import' => 'Importer les auteurs en masse',
	'Synchronize Users' => 'Synchroniser les utilisateurs',
	'Synchronize Groups' => 'Synchroniser les groupes',
	'Add user to group' => 'Ajouter l\'utilisateur au groupe',

## addons/Enterprise.pack/app-wizard.yaml
	'This module is required in order to use the LDAP Authentication.' => 'Ce module est nécessaire pour utiliser l\'identification LDAP.',
	'This module is required in order to use SSL/TLS connection with the LDAP Authentication.' => 'Ce module est nécessaire pour utiliser les connections SSL/TLS avec l\'identification LDAP.',
	'This module and its dependencies are required in order to use CRAM-MD5, DIGEST-MD5 or LOGIN as a SASL mechanism.' => 'Ce module et ses dépendances sont requis afin d\'utiliser CRAM-MD5, DIGEST-MD5 ou LOGIN en tant que méchanisme SASL.',

## addons/Enterprise.pack/config.yaml
	'Permissions of group: [_1]' => 'Permissions du groupe [_1]',
	'Group' => 'Groupe',
	'Groups associated with author: [_1]' => 'Groupes associés avec l\'auteur : [_1]',
	'Inactive' => 'Inactif',
	'Members of group: [_1]' => 'Membres du groupe : [_1]',
	'Advanced Pack' => 'Advanced Pack',
	'User/Group' => 'Utilisateur/Groupe',
	'User/Group Name' => 'Nom d\'utilisateur/groupe',
	'__GROUP_MEMBER_COUNT' => 'Nombre de membres du groupe',
	'My Groups' => 'Mes groupes',
	'Group Name' => 'Nom du groupe',
	'Manage Group Members' => 'Gérer les membres du groupe',
	'Group Members' => ' Membres du groupe',
	'Group Member' => 'Membre du groupe',
	'Permissions for Users' => 'Permissions pour les utilisateurs',
	'Permissions for Groups' => 'Permissions pour les groupes',
	'Active Groups' => 'Groupes actifs',
	'Disabled Groups' => 'Groupes inactifs',
	'Oracle Database (Recommended)' => 'Base de données Oracle (Recommendé)',
	'Microsoft SQL Server Database' => 'Base de données Microsoft SQL Server',
	'Microsoft SQL Server Database UTF-8 support (Recommended)' => 'Support UTF-8 Base de données Microsoft SQL Server (recommendé)',
	'Publish Charset' => 'Publier le  Charset',
	'ODBC Driver' => 'Pilote ODBC',
	'External Directory Synchronization' => 'Synchronization répertoire externe',
	'Populating author\'s external ID to have lower case user name...' => 'Peuplement de l\'ID externe d\'auteur pour avoir des identifiants en minuscule...',

## addons/Enterprise.pack/lib/MT/Auth/LDAP.pm
	'User [_1]([_2]) not found.' => 'Utilisateur [_1]([_2]) non trouvé.',
	'User \'[_1]\' cannot be updated.' => 'Utilisateur \'[_1]\' ne peut être mis à jour.',
	'User \'[_1]\' updated with LDAP login ID.' => 'Utilisateur \'[_1]\' mis à jour avec l\'ID de login LDAP.',
	'LDAP user [_1] not found.' => 'Utilisateur LDAP [_1] non trouvé.',
	'User [_1] cannot be updated.' => 'Utilisateur [_1] ne peut être mis à jour.',
	'User cannot be updated: [_1].' => 'Utilisateur ne peut être mis à jour: [_1].',
	'Failed login attempt by user \'[_1]\' who was deleted from LDAP.' => 'Échec lors de la tentative d\'identification de l\'utilisateur \'[_1]\' qui a été supprimé de LDAP',
	'User \'[_1]\' updated with LDAP login name \'[_2]\'.' => 'Utilisateur \'[_1]\' mis à jour avec l\'identifiant LDAP \'[_2]\'.',
	'Failed login attempt by user \'[_1]\'. A user with that username already exists in the system with a different UUID.' => 'Échec lors de la tentative d\'identification de l\'utilisateur \'[_1]\'. Un utilisateur avec ce nom d\'utilisateur existe déjà dans le système avec un UUID différent.',
	'User \'[_1]\' account is disabled.' => 'Le compte de l\'utilisateur \'[_1]\' est désactivé.',
	'LDAP users synchronization interrupted.' => 'Synchronisation des utilisateurs LDAP interrompue.',
	'Loading MT::LDAP failed: [_1]' => 'Chargement de MT::LDAP échoué: [_1]',
	'External user synchronization failed.' => 'Synchronisation utilisateur externe échouée.',
	'An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted.' => 'Une tentative de désactivation de tous les administrateurs système a été réalisée. La synchronisation des utilisateurs a été interrompue.',
	'Information about the following users was modified:' => 'Une information à propos des utilisateurs suivants a été modifiée :',
	'The following users were disabled:' => 'Les utilisateurs suivants ont été désactivés:',
	'LDAP users synchronized.' => 'Utilisateurs LDAP synchronisés.',
	'Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set.' => 'La synchronisation des groupes ne peut pas être faite sans la configuration de LDAPGroupIdAttribute et/ou LDAPGroupNameAttribute.',
	'LDAP groups synchronized with existing groups.' => 'Groupes LDAP synchronisés avec les groupes existants.',
	'Information about the following groups was modified:' => 'Une information à propos des groupes suivants a été modifiée :',
	'No LDAP group was found using the filter provided.' => 'Aucun groupe LDAP n\'a été trouvé en utilisant le filtre indiqué.',
	'The filter used to search for groups was: \'[_1]\'. Search base was: \'[_2]\'' => 'Le filtre utilisé pour la recherche dans les groupes était : \'[_1]\'. La base de la recherche était : \'[_2]\'',
	'(none)' => '(Aucun)',
	'The following groups were deleted:' => 'Les groupes suivants ont été effacés:',
	'Failed to create a new group: [_1]' => 'Impossible de créer un nouveau groupe: [_1]',
	'[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.' => 'La directive [_1] doit être configurée pour synchroniser les membres des groupes LDAP avec Movable Type Advanced.',
	'Members removed: ' => 'Membres supprimés:',
	'Members added: ' => 'Membres ajoutés:',
	'Memberships in the group \'[_2]\' (#[_3]) were changed as a result of synchronizing with the external directory.' => 'Les appartenances au groupe \'[_2] (#[_3]) ont été changées par la synchronisation avec l\'annuaire externe.',
	'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.' => 'LDAPUserGroupMemberAttribute doit être configuré pour permettre la synchronisation des membres des groupes.',

## addons/Enterprise.pack/lib/MT/Enterprise/Author.pm
	'Loading MT::LDAP failed: [_1].' => 'Échec de Chargement MT::LDAP[_1]',

## addons/Enterprise.pack/lib/MT/Enterprise/BulkCreation.pm
	'Formatting error at line [_1]: [_2]' => 'Erreur de formattage à la ligne [_1] : [_2]',
	'Invalid command: [_1]' => 'Commande invalide: [_1]',
	'Invalid number of columns for [_1]' => 'Nombre de colonnes invalide pour [_1]',
	'Invalid user name: [_1]' => 'Identifiant invalide: [_1]',
	'Invalid display name: [_1]' => 'Nom d\'affichage invalide: [_1]',
	'Invalid email address: [_1]' => 'Adresse email invalide: [_1]',
	'Invalid language: [_1]' => 'Langue invalide: [_1]',
	'Invalid password: [_1]' => 'Mot de passe invalide: [_1]',
	'\'Personal Blog Location\' setting is required to create new user blogs.' => 'Le paramètre \'Localisation du blog personnel\' est nécessaire pour créer de nouveaux blogs utilisateur',
	'Invalid weblog name: [_1]' => 'Nom de weblog invalide: [_1]',
	'Invalid blog URL: [_1]' => 'URL de blog invalide : [_1]',
	'Invalid site root: [_1]' => 'Racine du site invalide : [_1]',
	'Invalid timezone: [_1]' => 'Fuseau horaire invalide : [_1]',
	'Invalid theme ID: [_1]' => 'ID de thème invalide : [_1]',
	'A user with the same name was found.  The registration was not processed: [_1]' => 'Un utilisateur avec le même nom a été trouvé. L\'entregistrement n\'a pas été effectué : [_1]',
	'Blog for user \'[_1]\' can not be created.' => 'Le blog pour l\'utilisateur \'[_1]\' ne peut être créé.',
	'Blog \'[_1]\' for user \'[_2]\' has been created.' => 'Le blog \'[_1]\' pour l\'utilisateur \'[_2]\' a été créé.',
	'Error assigning weblog administration rights to user \'[_1] (ID: [_2])\' for weblog \'[_3] (ID: [_4])\'. No suitable weblog administrator role was found.' => 'Erreur en tentant d\'assigner les droits d\'administration du blog à l\'utilisateur \'[_1] (ID: [_2])\' pour le weblog \'[_3] (ID: [_4])\'. Aucun rôle d\'administrateur de weblog adéquat n\'a été trouvé.',
	'Permission granted to user \'[_1]\'' => 'Permission accordée à l\'utilisateur \'[_1]\'',
	'User \'[_1]\' already exists. The update was not processed: [_2]' => 'L\'utilisateur \'[_1] existe déjà. La mise à jour n\'a pas continué : [_2]',
	'User \'[_1]\' not found.  The update was not processed.' => 'L\'utilisateur \'[_1] n\'a pas trouvé. La mise à jour n\'a pas continué.',
	'User \'[_1]\' has been updated.' => 'L\'utilisateur \'[_1]\' a été mis à jour.',
	'User \'[_1]\' was found, but the deletion was not processed' => 'L\'utilisateur \'[_1] a été trouvé, mais la suppression n\'a pas été effectuée.',
	'User \'[_1]\' not found.  The deletion was not processed.' => 'L\'utilisateur \'[_1] n\'a pas trouvé. La suppression n\'a pas été effectuée.',
	'User \'[_1]\' has been deleted.' => 'L\'utilisateur \'[_1]\' a été supprimé.',

## addons/Enterprise.pack/lib/MT/Enterprise/CMS.pm
	q{Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding.} => q{Movable Type Advanced vient de tenter de désactiver votre compte pendant la synchronisation avec l'annuaire externe. Certains des paramètres du système de gestion externe des utilisateurs doivent être erronés. Merci de corriger avant de poursuivre.},
	'Each group must have a name.' => 'Chaque groupe doit avoir un nom.',
	'Search Users' => 'Rechercher des utilisateurs',
	'Select Groups' => 'Sélectionner les groupes',
	'Groups Selected' => 'Groupes sélectionnés',
	'Search Groups' => 'Rechercher des groupes',
	'Add Users to Groups' => 'Ajouter des utilisateurs aux groupes',
	'Invalid group' => 'Groupe invalide.',
	'Add Users to Group [_1]' => 'Ajouter les utilisateurs au groupe [_1]',
	'User \'[_1]\' (ID:[_2]) removed from group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Utilisateur \'[_1]\' (ID:[_2]) supprimé du groupe \'[_3]\' (ID:[_4]) par \'[_5]\'',
	'Group load failed: [_1]' => 'Chargement du groupe échoué: [_1]',
	'User load failed: [_1]' => 'Chargement de l\'utilisateur échoué: [_1]',
	'User \'[_1]\' (ID:[_2]) was added to group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Utilisateur \'[_1]\' (ID:[_2]) a été ajouté au groupe \'[_3]\' (ID:[_4]) par \'[_5]\'',
	'Users & Groups' => 'Utilisateurs et Groupes',
	'Group Profile' => 'Profil du Groupe',
	'Author load failed: [_1]' => 'Chargement de l\'auteur échoué: [_1]',
	'Invalid user' => 'Utilisateur invalide',
	'Assign User [_1] to Groups' => 'Assigner l\'utilisateur [_1] aux groupes.',
	'Type a group name to filter the choices below.' => 'Tapez un nom de groupe pour filtrer les choix ci-dessous.',
	'Bulk import cannot be used under external user management.' => 'L\'import en masse ne peut être utilisé avec la gestion externe des utilisateurs.',
	'Bulk management' => 'Gestion en masse',
	'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.' => 'Aucun enregistrement n\'a été trouvé dans le fichier. Veuillez vous assurer que le fichier utilise CRLF comme caractère de fin de ligne.',
	'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].' => 'Création de [quant,_1,utilisateur,utilisateurs], modification de [quant,_2, utilisateur, utilisateurs], suppression de [quant,_3, utilisateur, utilisateurs].',
	'Bulk author export cannot be used under external user management.' => 'L\'exportation par lot ne peut pas être utilisé lors d\'une gestion des utilisateurs externe.',
	'A user can\'t change his/her own username in this environment.' => 'Un utilisateur ne peut pas changer son nom d\'utilisateur dans cet environnement',
	'An error occurred when enabling this user.' => 'Une erreur s\'est produite pendant l\'activation de cet utilisateur.',

## addons/Enterprise.pack/lib/MT/Enterprise/Upgrade.pm
	'Fixing binary data for Microsoft SQL Server storage...' => 'Correction des données binaires pour le stockage Microsoft SQL Server...',

## addons/Enterprise.pack/lib/MT/Enterprise/Wizard.pm
	'PLAIN' => 'PLAIN',
	'CRAM-MD5' => 'CRAM-MD5',
	'Digest-MD5' => 'Digest-MD5',
	'Login' => 'Identifiant',
	'Found' => 'Trouvé',
	'Not Found' => 'Non trouvé',

## addons/Enterprise.pack/lib/MT/Group.pm

## addons/Enterprise.pack/lib/MT/LDAP.pm
	'Invalid LDAPAuthURL scheme: [_1].' => 'LDAPAuthURL invalide : [_1].',
	'Either your server does not have [_1] installed, the version that is installed is too old, or [_1] requires another module that is not installed.' => 'Soit votre serveur n\'a pas [_1] d\'installé, soit la version installée est trop vieille, ou [_1] nécessite un autre module qui n\'est pas installé',
	'Error connecting to LDAP server [_1]: [_2]' => 'Erreur de connection au serveur LDAP [_1]: [_2]',
	'User not found in LDAP: [_1]' => 'L\'utilisateur n\'a pas été trouvé dans LDAP : [_1]',
	'Binding to LDAP server failed: [_1]' => 'Rattachement au serveur LDAP échoué: [_1]',
	'More than one user with the same name found in LDAP: [_1]' => 'Plus d\'un utilisateur avec le même nom a été trouvé dans LDAP : [_1]',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/MSSQLServer.pm
	'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.' => 'PublishCharset [_1] n\'est pas supporté dans cette version du pilote MS SQL Server.',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/UMSSQLServer.pm
	'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.' => 'Cette version du driver UMSSQLServer nécessite DBD::ODBC version 1.14.',
	'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.' => 'Cette version du driver UMSSQLServer nécessite DBD::ODBC compilé avec le support de Unicode.',

## addons/Enterprise.pack/tmpl/author_bulk.tmpl
	'Manage Users in bulk' => 'Gérer les utilisateurs en masse',
	'_USAGE_AUTHORS_2' => 'Vous pouvez créer, modifier et effacer des utilisateurs en masse en chargeant un fichier CSV contenant ces commandes et les données associées.',
	q{New user blog would be created on '[_1]'.} => q{Un nouveau blog d'utilisateur serait créé sur '[_1]'.},
	'[_1] Edit</a>' => 'Éditer du [_1]',
	q{You must set 'Personal Blog Location' to create a new blog for each new user.} => q{Vous devez paramétrer 'L'emplacement du blog persomnel' pour créer un blog pour chaque utilisateur.},
	'[_1] Setting</a>' => 'Paramètre du [_1]',
	'Upload source file' => 'Charger le fichier source',
	'Specify the CSV-formatted source file for upload' => 'Spécifier le fichier source CSV à charger',
	'Source File Encoding' => 'Encodage du fichier source',
	q{Movable Type will automatically try to detect the character encoding of your import file.  However, if you experience difficulties, you can set the character encoding explicitly.} => q{Movable Type va automatiquement essayer de détecter le système d'encodage de votre fichier d'importation. Cependant, si cela ne fonctionne pas, vous pouvez spécifier explicitement le système d'encodage.},
	'Upload (u)' => 'Charger (u)',

## addons/Enterprise.pack/tmpl/cfg_ldap.tmpl
	q{Authentication Configuration} => q{Configuration de l'identification},
	q{You must set your Authentication URL.} => q{Vous devez configurer votre URL d'identification.},
	'You must set your Group search base.' => 'Vous devez configurer votre base de recherche de groupes.',
	'You must set your UserID attribute.' => 'Vous devez configurer votre attribut UserID.',
	'You must set your email attribute.' => 'Vous devez configurer votre attribut email.',
	q{You must set your user fullname attribute.} => q{Vous devez configurer votre attribut nom complet de l'utilisateur.},
	q{You must set your user member attribute.} => q{Vous devez configurer votre attribut de membre de l'utilisateur.},
	'You must set your GroupID attribute.' => 'Vous devez configurer votre attribut GroupID.',
	'You must set your group name attribute.' => 'Vous devez configurer votre attribut nom de groupe.',
	'You must set your group fullname attribute.' => 'Vous devez configurer votre attribut nom complet du groupe.',
	'You must set your group member attribute.' => 'Vous devez configurer votre attribut member du groupe.',
	q{An error occurred while attempting to connect to the LDAP server: } => q{Une erreur s'est produite en essayant de se connecter au serveur LDAP:},
	q{You can configure your LDAP settings from here if you would like to use LDAP-based authentication.} => q{Vous devez configurer vos réglages LDAP ici si vous souhaitez utiliser l'identification LDAP.},
	'Your configuration was successful.' => 'Votre configuration est correcte.',
	q{Click 'Continue' below to configure the External User Management settings.} => q{Cliquez sur 'Continuer' ci-dessous pour configurer les réglages de la gestion externe des utilisateurs.},
	q{Click 'Continue' below to configure your LDAP attribute mappings.} => q{Cliquez sur 'Continuer' ci-dessous pour configurer vos rattachements des attributs LDAP.},
	'Your LDAP configuration is complete.' => 'Votre configuration LDAP est terminée.',
	q{To finish with the configuration wizard, press 'Continue' below.} => q{Pour finir l'assistant de configuration, cliquez sur 'Continuer' ci-dessous.},
	q{Can't locate Net::LDAP. Net::LDAP module is required to use LDAP authentication.} => q{Net::LDAP impossible à localiser. Le module Net::LDAP est requis pour l'authentification LDAP.},
	'Use LDAP' => 'Utiliser LDAP',
	q{Authentication URL} => q{URL d'identification},
	q{The URL to access for LDAP authentication.} => q{L'URL pour accéder à l'identification LDAP.},
	'Authentication DN' => 'Identificatiin DN',
	q{An optional DN used to bind to the LDAP directory when searching for a user.} => q{Un DN optionnel utilisé pour rattacher à l'annuaire LDAP lors d'une recherche d'utilisateur.},
	q{Authentication password} => q{Mot de passe de l'identification},
	'Used for setting the password of the LDAP DN.' => 'Utilisé pour régler le mot de passe du DN LDAP.',
	'SASL Mechanism' => 'Mécanisme SASL',
	q{The name of the SASL Mechanism used for both binding and authentication.} => q{Le nom du mécanisme SASL est utilisé pour l'association et l'authentification.},
	'Test Username' => 'Identifiant de test',
	'Test Password' => 'Mot de passe de test',
	'Enable External User Management' => 'Activer les gestion externe des utilisateurs',
	'Synchronization Frequency' => 'Fréquence de synchronisation',
	'The frequency of synchronization in minutes. (Default is 60 minutes)' => 'La fréquence de synchronisation en minutes. (60 minutes par défaut).',
	'15 Minutes' => '15 Minutes',
	'30 Minutes' => '30 Minutes',
	'60 Minutes' => '60 Minutes',
	'90 Minutes' => '90 Minutes',
	'Group Search Base Attribute' => 'Attribut de base de recherche du groupe',
	'Group Filter Attribute' => 'Attribut de filtre du groupe',
	'Search Results (max 10 entries)' => 'Résultats de recherche (maxi 10 entrées)',
	'CN' => 'CN',
	q{No groups were found with these settings.} => q{Aucun groupe n'a été trouvé avec ces réglages.},
	q{Attribute mapping} => q{Rattachement d'attribut},
	'LDAP Server' => 'Serveur LDAP',
	'Other' => 'Autre',
	'User ID Attribute' => 'Attribut ID utilisateur',
	'Email Attribute' => 'Attribut email',
	'User Fullname Attribute' => 'Attribut nom complet utilisateur',
	'User Member Attribute' => 'Attribut membre utilisateur',
	'GroupID Attribute' => 'Attribut GroupID',
	'Group Name Attribute' => 'Attribut nom du groupe',
	'Group Fullname Attribute' => 'Attribut nom complet du groupe',
	'Group Member Attribute' => 'Attribut membre du groupe',
	'Search Result (max 10 entries)' => 'Résultat de recherche (maxi 10 entrées)',
	'Group Fullname' => 'Nom complet du groupe',
	'(and [_1] more members)' => '(et [_1] membres en plus)',
	q{No groups could be found.} => q{Aucun groupe n'a été trouvé.},
	'User Fullname' => 'Nom complet utilisateur',
	'(and [_1] more groups)' => '(et [_2] groupes en plus)',
	q{No users could be found.} => q{Aucun utilisateur n'a été trouvé.},
	'Test connection to LDAP' => 'Tester la connection à LDAP',
	'Test search' => 'Tester la recherche',

## addons/Enterprise.pack/tmpl/create_author_bulk_end.tmpl
	'All users were updated successfully.' => 'Tous les utilisateurs ont été mis à jour avec succès',
	'An error occurred during the update process. Please check your CSV file.' => 'Une erreur est apparue lors du processus de mise à jour. Veuillez vérifier votre fichier CSV.',

## addons/Enterprise.pack/tmpl/create_author_bulk_start.tmpl

## addons/Enterprise.pack/tmpl/dialog/dialog_select_group_user.tmpl

## addons/Enterprise.pack/tmpl/dialog/select_groups.tmpl
	'You need to create some groups.' => 'Vous devez créer des groupes',
	q{Before you can do this, you need to create some groups. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Click here</a> to create a group.} => q{Avant de pouvoir faire ceci, vous devez créer des groupes. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Cliquez ici</a> pour créer un groupe.},

## addons/Enterprise.pack/tmpl/edit_group.tmpl
	'Edit Group' => 'Modifier le groupe',
	'Create Group' => 'Créer un groupe',
	'This group profile has been updated.' => 'Ce profil de groupe a été mis à jour.',
	'This group was classified as pending.' => 'Ce groupe a été classé comme en attente.',
	'This group was classified as disabled.' => 'Ce groupe a été classé comme désactivé.',
	'Member ([_1])' => 'Membre ([_1])',
	'Members ([_1])' => 'Membres ([_1])',
	'Permission ([_1])' => 'Permission ([_1])',
	'Permissions ([_1])' => 'Permissions ([_1])',
	'LDAP Group ID' => 'Group ID LDAP',
	q{The LDAP directory ID for this group.} => q{L'ID de l'annuaire LDAP pour ce groupe.},
	q{Status of this group in the system. Disabling a group prohibits its members&rsquo; from accessing the system but preserves their content and history.} => q{Le statut de ce groupe dans le système. Désactiver un groupe empêche ses membres d'accéder au système mais conserve leur contenu et leur historique.},
	'The name used for identifying this group.' => 'Le nom utilisé pour identifier ce groupe.',
	q{The display name for this group.} => q{Le nom d'affichage de ce groupe.},
	'The description for this group.' => 'La description de ce groupe.',
	'Save changes to this field (s)' => 'Sauvegarder les changements apportés à ce champ (s)',

## addons/Enterprise.pack/tmpl/include/group_table.tmpl
	'Enable selected group (e)' => 'Activer le groupe sélectionné (e)',
	'Disable selected group (d)' => 'Désactiver le groupe sélectionné (d)',
	'group' => 'groupe',
	'groups' => 'Groupes',
	'Remove selected group (d)' => 'Supprimer le groupe sélectionné (d)',

## addons/Enterprise.pack/tmpl/include/list_associations/page_title.group.tmpl
	'Users &amp; Groups for [_1]' => 'Utilisateurs &amp; groupes pour [_1]',

## addons/Enterprise.pack/tmpl/listing/group_list_header.tmpl
	'You successfully disabled the selected group(s).' => 'Vous avez désactivé les groupes sélectionnés avec succès.',
	'You successfully enabled the selected group(s).' => 'Vous avez activé les groupes sélectionnés avec succès.',
	'You successfully deleted the groups from the Movable Type system.' => 'Vous avez supprimé les groupes du système Movable Type.',
	q{You successfully synchronized the groups' information with the external directory.} => q{Vous avez synchronisé les informations des groupes avec l'annuaire externe avec succès.},

## addons/Enterprise.pack/tmpl/listing/group_member_list_header.tmpl
	'You successfully deleted the users.' => 'Vous avez supprimé avec succès les utilisateurs.',
	'You successfully added new users to this group.' => 'Vous avez ajouté de nouveaux utilisateurs dans ce groupe avec succès.',
	q{You successfully synchronized users' information with the external directory.} => q{Vous avez synchronisé les informations des utilisateurs avec l'annuaire externe avec succès.},
	'Some ([_1]) of the selected users could not be re-enabled because they are no longer found in LDAP.' => 'Quelques ([_1]) des utilisateurs sélectionnés ne peuvent pas être réactivés car ils ne sont plus trouvés dans LDAP',
	'You successfully removed the users from this group.' => 'Vous avez retiré avec succès les utilisateurs de ce groupe.',
);

1;
