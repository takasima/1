# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::L10N::es;

use strict;
use base 'MT::Enterprise::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Enterprise.pack/app-cms.yaml
	'Groups ([_1])' => 'Grupos ([_1])',
	'Are you sure you want to delete the selected group(s)?' => '¿Está seguro de querer borrar el(los) grupo(s) seleccionados?',
	'Are you sure you want to remove the selected member(s) from the group?' => '¿Está seguro de querer borrar los miembros seleccionados del grupo?',
	'[_1]\'s Group' => 'Grupo de [_1]', # Translate - New
	'Groups' => 'Grupos',
	'Manage Member' => 'Administrar miembros',
	'Bulk Author Export' => 'Exportación masiva de autores',
	'Bulk Author Import' => 'Importación de autores por lote',
	'Synchronize Users' => 'Sincronización de Usuarios',
	'Synchronize Groups' => 'Sincronizar grupos',
	'Add user to group' => 'Añadir usuario a grupo',

## addons/Enterprise.pack/app-wizard.yaml
	'This module is required in order to use the LDAP Authentication.' => 'Este módulo es requerido para usar la identificación LDAP.',
	'This module is required in order to use SSL/TLS connection with the LDAP Authentication.' => 'Este módulo es necesario para usar la conexión SSL/TLS con la autentificación LDAP.',
	'This module and its dependencies are required in order to use CRAM-MD5, DIGEST-MD5 or LOGIN as a SASL mechanism.' => 'Este módulo y sus dependencias son necesarios para usar CRAM-MD5, DIGEST-MD5 o LOGIN como mecanismo SASL.',

## addons/Enterprise.pack/config.yaml
	'Permissions of group: [_1]' => 'Permisos del grupo: [_1]',
	'Group' => 'Grupo',
	'Groups associated with author: [_1]' => 'Grupos asociados con autor: [_1]',
	'Inactive' => 'Inactivo',
	'Members of group: [_1]' => 'Miembros del grupo: [_1]',
	'Advanced Pack' => 'Advanced Pack',
	'User/Group' => 'Usuario/Grupo',
	'User/Group Name' => 'Nombre del usuario/grupo',
	'__GROUP_MEMBER_COUNT' => 'Miembros',
	'My Groups' => 'Mis grupos',
	'Group Name' => 'Nombre del grupo',
	'Manage Group Members' => 'Administrar miembros del grupo',
	'Group Members' => 'Miembros del grupo',
	'Group Member' => 'Miembro del grupo',
	'Permissions for Users' => 'Permisos para usuarios',
	'Permissions for Groups' => 'Permisos para grupos',
	'Active Groups' => 'Grupos activos',
	'Disabled Groups' => 'Grupos deshabilitados',
	'Oracle Database (Recommended)' => 'Base de datos Oracle (recomendada)',
	'Microsoft SQL Server Database' => 'Base de Datos Microsoft SQL Server',
	'Microsoft SQL Server Database UTF-8 support (Recommended)' => 'Base de datos Microsoft SQL Server con soporte UTF-8 (recomendada)',
	'Publish Charset' => 'Código de caracteres',
	'ODBC Driver' => 'Controlador ODBC',
	'External Directory Synchronization' => 'Sincronización del Directorio Externo',
	'Populating author\'s external ID to have lower case user name...' => 'Introduciendo el ID externo del autor para usar minúsculas...',

## addons/Enterprise.pack/lib/MT/Auth/LDAP.pm
	'User [_1]([_2]) not found.' => 'Usuario [_1]([_2]) sin resultado.',
	'User \'[_1]\' cannot be updated.' => 'Usuario [_1] no puede ser modificado.',
	'User \'[_1]\' updated with LDAP login ID.' => 'Usuario [_1] modificado con el ID de login LDAP.',
	'LDAP user [_1] not found.' => 'Usuario LDAP [_1] sin resultado.',
	'User [_1] cannot be updated.' => 'Usuario [_1] no puede ser actualizado.',
	'User cannot be updated: [_1].' => 'Usuario no puede ser actualizado [_1].',
	'Failed login attempt by user \'[_1]\' who was deleted from LDAP.' => 'Falló el intento de inicio de sesión del usuario \'[_1]\' que fue borrado de LDAP.',
	'User \'[_1]\' updated with LDAP login name \'[_2]\'.' => 'Usuario [_1] actualizado con el nombre de login LDAP [_2]',
	'Failed login attempt by user \'[_1]\'. A user with that username already exists in the system with a different UUID.' => 'Falló el intento de inicio de sesión del usuario \'[_1]\'. Existe un usuario con ese nombre en el sistema con un UUID diferente.',
	'User \'[_1]\' account is disabled.' => 'La cuenta del usuario [_1] ha sido desactivada.',
	'LDAP users synchronization interrupted.' => 'La sincronización de los usuarios LDAP ha sido interrumpida.',
	'Loading MT::LDAP failed: [_1]' => 'El cargamiento de MT::LDAP falló: [_1]',
	'External user synchronization failed.' => 'La sincronización de los usuarios externos falló.',
	'An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted.' => 'Un intento de desactivación de todos los administradores del sistema ha sido efectuada.  La sincronización de los usuarios ha sido interrumpida.',
	'Information about the following users was modified:' => 'Se ha modificado la información de los siguiente usuarios:',
	'The following users were disabled:' => 'Los siguientes usuarios han sido desactivados:',
	'LDAP users synchronized.' => 'Los usuarios LDAP han sido sincronizados:',
	'Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set.' => 'No se puede realizar la sincronización de grupos sin configurar LDAPGroupIdAttribute y/o LDAPGroupNameAttribute.',
	'LDAP groups synchronized with existing groups.' => 'Grupos LDAP sincronizados con los grupos existentes.',
	'Information about the following groups was modified:' => 'Se ha modificado la información de los siguientes grupos:',
	'No LDAP group was found using the filter provided.' => 'No se han encontrado grupos LDAP usando el filtro indicado.',
	'The filter used to search for groups was: \'[_1]\'. Search base was: \'[_2]\'' => 'El filtro utilizado para la búsqueda de grupos era: \'[_1]\'. La búsqueda base eras: \'[_2]\'',
	'(none)' => '(ninguno)',
	'The following groups were deleted:' => 'Los siguientes grupos han sido borrados:',
	'Failed to create a new group: [_1]' => 'Falló la creación de un nuevo grupo: [_1]',
	'[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.' => 'La instrucción [_1] debe ser completada para sincronizar los miembros de los grupos LDAP en MT Advanced.',
	'Members removed: ' => 'Miembros borrados:',
	'Members added: ' => 'Miembros añadidos:',
	'Memberships in the group \'[_2]\' (#[_3]) were changed as a result of synchronizing with the external directory.' => 'Se modificó la pertenencia en el grupo \'[_2]\' (#[_3]) por la sincronización con el directorio externo.',
	'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.' => 'Debe configurar LDAPUserGroupMemberAttribute para permitir la sincronización de los miembros de los grupos.',

## addons/Enterprise.pack/lib/MT/Enterprise/Author.pm
	'Loading MT::LDAP failed: [_1].' => 'Falló la carga de MT::LDAP: [_1].',

## addons/Enterprise.pack/lib/MT/Enterprise/BulkCreation.pm
	'Formatting error at line [_1]: [_2]' => 'Error de formato en la línea [_1]: [_2]',
	'Invalid command: [_1]' => 'Orden inválida',
	'Invalid number of columns for [_1]' => 'Número de columnas para [_1] inválido',
	'Invalid user name: [_1]' => 'Nombre de usuario inválido: [_1]',
	'Invalid display name: [_1]' => 'Nombre mostrado inválido: [_1]',
	'Invalid email address: [_1]' => 'Dirección de correo electrónico inválida: [_1]',
	'Invalid language: [_1]' => 'Idioma inválido: [_1]',
	'Invalid password: [_1]' => 'Contraseña inválida: [_1]',
	'\'Personal Blog Location\' setting is required to create new user blogs.' => 'Se debe configurar \'Localización del blog personal\' para crear nuevos blogs de usuario.',
	'Invalid weblog name: [_1]' => 'Nombre de weblog no válido: [_1]',
	'Invalid blog URL: [_1]' => 'URL del blog no válidaL: [_1]',
	'Invalid site root: [_1]' => 'Raíz del sitio inválida: [_1]',
	'Invalid timezone: [_1]' => 'Zona horaria inválida: [_1]',
	'Invalid theme ID: [_1]' => 'ID de tema no válido: [_1]',
	'A user with the same name was found.  The registration was not processed: [_1]' => 'Se encontró un usuario con el mismo nombre. No se procesó el registro: [_1]',
	'Blog for user \'[_1]\' can not be created.' => 'El blog por el usuario [_1] no puede ser creado.',
	'Blog \'[_1]\' for user \'[_2]\' has been created.' => 'El blog [_1] por el usuario [_2] ha sido creado.',
	'Error assigning weblog administration rights to user \'[_1] (ID: [_2])\' for weblog \'[_3] (ID: [_4])\'. No suitable weblog administrator role was found.' => 'Error en la asignación de los derechos de administración al usuario [_1] (ID: [_2]) para el weblog [_3] (ID: [_4]).  Ningún rol de administrador apropiado ha sido encontrado.',
	'Permission granted to user \'[_1]\'' => 'Los derechos han sido atribuidos al usuario [_1]',
	'User \'[_1]\' already exists. The update was not processed: [_2]' => 'El usuario \'[_1]\' ya existe. No se ha procesado la actualización: [_2]',
	'User \'[_1]\' not found.  The update was not processed.' => 'No se encontró al usuario \'[_1]\'. No se ha procesado la actualización.',
	'User \'[_1]\' has been updated.' => 'Usuario [_1] ha sido actualizado.',
	'User \'[_1]\' was found, but the deletion was not processed' => 'Se encontró al usuario \'[_1]\' pero el borrado no se ha procesado',
	'User \'[_1]\' not found.  The deletion was not processed.' => 'No se encontró al usuario \'[_1]\'. El borrado no ha sido procesado.',
	'User \'[_1]\' has been deleted.' => 'El usuario [_1] ha sido borrado.',

## addons/Enterprise.pack/lib/MT/Enterprise/CMS.pm
	'Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding.' => 'Movable Type Advanced acaba de intentar deshabilitar su cuenta durante una sincronización con el directorio externo. Algunas de las opciones de configuración de la administración externa de usuarios deben ser incorrectas. Por favor, corrija la configuración antes de continuar.',
	'Each group must have a name.' => 'Cada grupo debe tener un nombre.',
	'Search Users' => 'Buscar usuarios',
	'Select Groups' => 'Seleccionar grupos',
	'Groups Selected' => 'Grupos seleccionados',
	'Search Groups' => 'Buscar grupos',
	'Add Users to Groups' => 'Añadir usuarios a grupos',
	'Invalid group' => 'Grupo inválido',
	'Add Users to Group [_1]' => 'Añadir usuarios al grupo [_1]',
	'User \'[_1]\' (ID:[_2]) removed from group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Usuario [_1] (ID: [_2]) ha sido borrado del grupo [_3] (ID:[_4]) por [_5]',
	'Group load failed: [_1]' => 'La carga del grupo ha fallado: [_1]',
	'User load failed: [_1]' => 'La carga del usuario ha fallado: [_1]',
	'User \'[_1]\' (ID:[_2]) was added to group \'[_3]\' (ID:[_4]) by \'[_5]\'' => 'Usuario[_1] (ID: [_2]) ha sido añadido del grupo [_3] (ID:[_4]) por [_5]',
	'Users & Groups' => 'Usuarios y grupos',
	'Group Profile' => 'Perfil de grupo',
	'Author load failed: [_1]' => 'La carga del autor ha fallado: [_1]',
	'Invalid user' => 'Usuario inválido',
	'Assign User [_1] to Groups' => 'Usuario [_1] asignado a los grupos',
	'Type a group name to filter the choices below.' => 'Tapea el nombre de un grupo para filtrar las opciones que se encuentran aquí debajo.',
	'Bulk import cannot be used under external user management.' => 'La importación masiva no puede ser usuada en la administración de usuarios externos.',
	'Bulk management' => 'Administración masiva',
	'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.' => 'No se encontraron registros en el fichero. Asegúrese de que el fichero usa CRLF como caracteres de final de línea.',
	'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].' => '[quant,_1,Usuario registro,Usuariosregistrados], [quant,_2,usuario actualizado,usuarios actualizados], [quant,_3,usuario eliminado,usuarios eliminados].',
	'Bulk author export cannot be used under external user management.' => 'No se puede usar la exportación en lote de autores bajo la administración externa de usuario.',
	'A user can\'t change his/her own username in this environment.' => 'Un usuario no puede cambiar su propio nombre en este contexto.',
	'An error occurred when enabling this user.' => 'Ocurrió un error cuando se habilitaba este usuario.',

## addons/Enterprise.pack/lib/MT/Enterprise/Upgrade.pm
	'Fixing binary data for Microsoft SQL Server storage...' => 'Reparando datos binarios para Microsoft SQL Server...',

## addons/Enterprise.pack/lib/MT/Enterprise/Wizard.pm
	'PLAIN' => 'PLAIN',
	'CRAM-MD5' => 'CRAM-MD5',
	'Digest-MD5' => 'Digest-MD5',
	'Login' => 'Login',
	'Found' => 'Encontrado',
	'Not Found' => 'No encontrado',

## addons/Enterprise.pack/lib/MT/Group.pm

## addons/Enterprise.pack/lib/MT/LDAP.pm
	'Invalid LDAPAuthURL scheme: [_1].' => 'Scheme LDAPAuthURL inválido: [_1].',
	'Error connecting to LDAP server [_1]: [_2]' => 'Error a la conexión al server LDAP [_1]: [_2]',
	'User not found in LDAP: [_1]' => 'No se encontró al usuario en LDAP: [_1]',
	'Binding to LDAP server failed: [_1]' => 'La asociación con el server LDAP ha fallado: [_1]',
	'More than one user with the same name found in LDAP: [_1]' => 'Se encontró en LDAP a más de un usuario con el mismo nombre: [_1]',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/MSSQLServer.pm
	'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.' => 'En esta versión del controlador de MS SQL Server PublishCharset [_1] no está soportado.',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/UMSSQLServer.pm
	'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.' => 'Esta versión del Driver UMSSQLServer requiere DBD::ODBC versión 1.14.',
	'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.' => 'Esta versión del Driver UMSSQLServer requiere DBD::ODBC compilado con el soporte Unicode.',

## addons/Enterprise.pack/tmpl/author_bulk.tmpl
	'Manage Users in bulk' => 'Administrar los usuarios por lote',
	'_USAGE_AUTHORS_2' => 'Puede crear editar y borrar usuarios en lote transfiriendo un fichero con formato CSV con las órdenes y datos relevantes.',
	q{New user blog would be created on '[_1]'.} => q{Se creará al nuevo blog de usuario en '[_1]'.},
	'[_1] Edit</a>' => 'Editar [_1]</a>',
	q{You must set 'Personal Blog Location' to create a new blog for each new user.} => q{Para crear un nuevo blog para cada usuario debe indicar la 'Localización del blog personal'.},
	'[_1] Setting</a>' => 'Configuración de [_1]</a>',
	'Upload source file' => 'Suba el fichero fuente',
	'Specify the CSV-formatted source file for upload' => 'Defina el fichero fuente en formato CSV para subirlo',
	'Source File Encoding' => 'Codificación del archivo fuente',
	'Movable Type will automatically try to detect the character encoding of your import file.  However, if you experience difficulties, you can set the character encoding explicitly.' => 'Movable Type intentará detectar automáticamente la codificación del fichero de exportación. Puede indicarlo explícitamente si observa problemas.',
	'Upload (u)' => 'Suba (u)',

## addons/Enterprise.pack/tmpl/cfg_ldap.tmpl
	'Authentication Configuration' => 'Configuración de la autentificación',
	'You must set your Authentication URL.' => 'Configure la URL de identificación.',
	'You must set your Group search base.' => 'Configure la base de búsqueda de Grupos.',
	'You must set your UserID attribute.' => 'Configure su parámetro UserID.',
	'You must set your email attribute.' => 'Configure su parámetro de correo electrónico.',
	'You must set your user fullname attribute.' => 'Configure su parámetro de nombre completo',
	'You must set your user member attribute.' => 'Configure su parámetro de nombre de usuario.',
	'You must set your GroupID attribute.' => 'Configure su parámetro de GroupID.',
	'You must set your group name attribute.' => 'Configure el parámetro de su nombre de grupo.',
	'You must set your group fullname attribute.' => 'Configure el parámetro del nombre completo del grupo.',
	'You must set your group member attribute.' => 'Configure el parámetro de su nombre de grupo.',
	'An error occurred while attempting to connect to the LDAP server: ' => 'Un error se ha producido durante la conexión LDAP.',
	'You can configure your LDAP settings from here if you would like to use LDAP-based authentication.' => 'Ahora puede configurar sus parámetros LDAP desde aquí si desea utilizar una identificaión basada sobre LDAP. ',
	'Your configuration was successful.' => 'Su configuración se ha producido con suceso.',
	q{Click 'Continue' below to configure the External User Management settings.} => q{Haga clic en continuar debajo para configurar la administración de usuario externo.},
	q{Click 'Continue' below to configure your LDAP attribute mappings.} => q{Haga clic en continuar debajo para configurar el mapeado de los atributos LDAP.},
	'Your LDAP configuration is complete.' => 'Su configuración LDAP ha sido completada.',
	q{To finish with the configuration wizard, press 'Continue' below.} => q{Para terminar con la configuración, haga clic en el botón continuar debajo.},
	q{Can't locate Net::LDAP. Net::LDAP module is required to use LDAP authentication.} => q{No se encontró Net::LDAP. El módulo Net::LDAP es necesario para utilizar la autentificación LDAP.},
	'Use LDAP' => 'Utilizar LDAP',
	'Authentication URL' => 'URL de Identificación',
	'The URL to access for LDAP authentication.' => 'La URL para acceder a la identificación LDAP',
	'Authentication DN' => 'DN de la Identificación',
	'An optional DN used to bind to the LDAP directory when searching for a user.' => 'Un DN opcional utilizado para asociarse con el directorio LDAP cuando se busca un usuario.',
	'Authentication password' => 'Contraseña de la Identificación',
	'Used for setting the password of the LDAP DN.' => 'Utilizado para iniciar la contraseña del DN del LDAP.',
	'SASL Mechanism' => 'Mecanismo SASL',
	'The name of the SASL Mechanism used for both binding and authentication.' => 'El nombre del mecanismo SASL utilizado para la conexión y autentificación.',
	'Test Username' => 'Verificar el nombre de usuario',
	'Test Password' => 'Verificar la contraseña',
	'Enable External User Management' => 'Activar la administración de los usuarios externos',
	'Synchronization Frequency' => 'Frecuencia de sincronización',
	'The frequency of synchronization in minutes. (Default is 60 minutes)' => 'La frecuencia de sincronización en minutos (Por defecto son 60 minutos)',
	'15 Minutes' => '15 Minutos',
	'30 Minutes' => '30 Minutos',
	'60 Minutes' => '60 Minutos',
	'90 Minutes' => '90 Minutos',
	'Group Search Base Attribute' => 'Atributo de la base de búsqueda de grupos',
	'Group Filter Attribute' => 'Atributo de filtro de grupos',
	'Search Results (max 10 entries)' => 'Resultados de la búsqueda (máx. 10 entradas)',
	'CN' => 'CN',
	'No groups were found with these settings.' => 'Ningún grupo ha sido encontrado bajo estos parámetros.',
	'Attribute mapping' => 'Mapeado de los atributos',
	'LDAP Server' => 'LDAP Server',
	'Other' => 'Otro',
	'User ID Attribute' => 'Atributo del ID de usuario',
	'Email Attribute' => 'Atributo del correo electrónico',
	'User Fullname Attribute' => 'Atributo del nombre completo',
	'User Member Attribute' => 'Atributo del nombre de usuario',
	'GroupID Attribute' => 'Atributo del ID de Grupo',
	'Group Name Attribute' => 'Atributo del nombre del grupo',
	'Group Fullname Attribute' => 'Atributo del nombre completo del grupo',
	'Group Member Attribute' => 'Atributo del nombre de usuario del grupo',
	'Search Result (max 10 entries)' => 'Resultado de la búsqueda (máx. 10 entradas)',
	'Group Fullname' => 'Nombre completo del grupo',
	'(and [_1] more members)' => '(y [_1] miembros más)',
	'No groups could be found.' => 'Ningún grupo ha sido encontrado',
	'User Fullname' => 'Nombre completo el usuario',
	'(and [_1] more groups)' => '(y [_1] grupos más)',
	'No users could be found.' => 'Ningún usuario ha sido encontrado',
	'Test connection to LDAP' => 'Verificación de la conexión LDAP',
	'Test search' => 'Verificación de la búsqueda',

## addons/Enterprise.pack/tmpl/create_author_bulk_end.tmpl
	'All users were updated successfully.' => 'Se actualizaron con éxito todos los usuarios.',
	'An error occurred during the update process. Please check your CSV file.' => 'Ocurrió un error durante el proceso de actualización. Por favor, compruebe el fichero CSV.',

## addons/Enterprise.pack/tmpl/create_author_bulk_start.tmpl

## addons/Enterprise.pack/tmpl/dialog/dialog_select_group_user.tmpl

## addons/Enterprise.pack/tmpl/dialog/select_groups.tmpl
	'You need to create some groups.' => 'Necesita crear algunos grupos.',
	q{Before you can do this, you need to create some groups. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Click here</a> to create a group.} => q{Antes de poder hacer esto, usted debe crear algunos grupos. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Haga clic aquí</a> para crear un grupo.},

## addons/Enterprise.pack/tmpl/edit_group.tmpl
	'Edit Group' => 'Editar grupo',
	'Create Group' => 'Crear grupo',
	'This group profile has been updated.' => 'Se ha actualizado el perfil del grupo.',
	'This group was classified as pending.' => 'Este grupo estaba clasificado como pendiente.',
	'This group was classified as disabled.' => 'Este grupo estaba clasificado como deshabilitado.',
	'Member ([_1])' => 'Miembro ([_1])',
	'Members ([_1])' => 'Miembros ([_1])',
	'Permission ([_1])' => 'Permiso ([_1])',
	'Permissions ([_1])' => 'Permisos ([_1])',
	'LDAP Group ID' => 'LDAP del Grupo ID',
	'The LDAP directory ID for this group.' => 'El ID del directorio LDAP para este grupo.',
	'Status of this group in the system. Disabling a group prohibits its members&rsquo; from accessing the system but preserves their content and history.' => 'El estado del grupo en el sistema. La deshabilitación de grupos prohíbe a sus miembros el acceso al sistema, pero mantiene los contenidos e historia.',
	'The name used for identifying this group.' => 'El nombre de usuario para identificar este grupo.',
	'The display name for this group.' => 'El nombre que se muestra para este grupo.',
	'The description for this group.' => 'La descripción de este grupo.',
	'Save changes to this field (s)' => 'Guardar cambios en el campo (s)',

## addons/Enterprise.pack/tmpl/include/group_table.tmpl
	'Enable selected group (e)' => 'Habilitar grupo seleccionado (e)',
	'Disable selected group (d)' => 'Deshabilitar grupo seleccionado (d)',
	'group' => 'grupo',
	'groups' => 'grupos',
	'Remove selected group (d)' => 'Borrar grupo seleccionado (d)',

## addons/Enterprise.pack/tmpl/include/list_associations/page_title.group.tmpl
	'Users &amp; Groups for [_1]' => 'Usuarios &amp; Grupos de [_1]',

## addons/Enterprise.pack/tmpl/listing/group_list_header.tmpl
	'You successfully disabled the selected group(s).' => 'Deshabilitó con éxito los grupos seleccionados.',
	'You successfully enabled the selected group(s).' => 'Habilitó con éxito los grupos seleccionados.',
	'You successfully deleted the groups from the Movable Type system.' => 'Borró con éxito los grupos del sistema Movable Type.',
	q{You successfully synchronized the groups' information with the external directory.} => q{Sincronizó con éxito la información de los grupos con el directorio externo.},

## addons/Enterprise.pack/tmpl/listing/group_member_list_header.tmpl
	'You successfully deleted the users.' => 'Borró los usuarios con éxito.',
	'You successfully added new users to this group.' => 'Añadió nuevos usuarios al grupo con éxito.',
	q{You successfully synchronized users' information with the external directory.} => q{Sincronizó con éxito la información de los usuarios con el directorio externo.},
	'Some ([_1]) of the selected users could not be re-enabled because they are no longer found in LDAP.' => 'No se pudo rehabilitar alguno ([_1]) de los usuarios seleccionados porque ya no se encuentran en LDAP.',
	'You successfully removed the users from this group.' => 'Ha borrado con éxito a los usuarios del grupo.',
);

1;
