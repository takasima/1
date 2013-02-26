# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::L10N::es;

use strict;
use base 'MT::Community::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Community.pack/config.yaml
    'http://www.sixapart.com/movabletype/' =>
        'http://www.sixapart.com/movabletype/',
    'Increase reader engagement - deploy features to your website that make it easier for your readers to engage with your content and your company.'
        => 'Incremente la satisfacción de los lectores - muestre nuevas características en el sitio web para facilitar que los lectores disfruten de sus contenidos y su compañía.',
    'Create forums where users can post topics and responses to topics.' =>
        'Cree foros donde los usuarios pueden publicar temas y respuestas a esos temas.',
    'Users followed by [_1]'    => 'Seguidos por [_1]',
    'Users following [_1]'      => 'Seguidores de [_1]',
    'Community'                 => 'Comunidad',
    'Sanitize'                  => 'Esterilizar',
    'Followed by'               => 'Seguido por',
    'Followers'                 => 'Seguidores',
    'Following'                 => 'Siguiendo',
    'Pending Entries'           => 'Entradas pendientes',
    'Spam Entries'              => 'Entradas spam',
    'Recently Scored'           => 'Puntuaciones recientes',
    'Recent Submissions'        => 'Envíos recientes',
    'Most Popular Entries'      => 'Entradas más populares',
    'Registrations'             => 'Registros',
    'Login Form'                => 'Formulario de inicio de sesión',
    'Registration Form'         => 'Formulario de registro',
    'Registration Confirmation' => 'Confirmación de registro',
    'Profile Error'             => 'Error del perfil',
    'Profile View'              => 'Ver perfil',
    'Profile Edit Form'         => 'Formulario de edición del perfil',
    'Profile Feed'              => 'Sindicación del perfil',
    'New Password Form'         => 'Formulario de nueva contraseña',
    'New Password Reset Form'   => 'Formulario de reinicio de contraseña',
    'Form Field'                => 'Campo del formulario',
    'Status Message'            => 'Mensaje de estado',
    'Simple Header'             => 'Cabecera simple',
    'Simple Footer'             => 'Pie simple',
    'Header'                    => 'Cabecera',
    'Footer'                    => 'Pie',
    'GlobalJavaScript'          => 'GlobalJavaScript',
    'Email verification'        => 'Verificación del correo',
    'Registration notification' => 'Notificación de registro',
    'New entry notification'    => 'Notificación de nueva entrada',
    'Community Styles'          => 'Estilos Comunitarios',
    'A collection of styles compatible with Community themes.' =>
        'Colección de estilos compatible con los temas Comunitarios.',
    'Community Blog' => 'Blog Comunitario',
    'Atom '          => 'Atom ',
    'Entry Response' => 'Respuesta a la entrada',
    'Displays error, pending or confirmation message when submitting an entry.'
        => 'Muestra un mensaje de error, de pendiente o de confirmación, al enviar una entrada.',
    'Entry Detail'       => 'Detalle de la entrada',
    'Entry Metadata'     => 'Metadatos de la entrada',
    'Page Detail'        => 'Detalle de la página',
    'Entry Form'         => 'Formulario de entradas',
    'Content Navigation' => 'Navegación de contenidos',
    'Activity Widgets'   => 'Widgets de actividad',
    'Archive Widgets'    => 'Widgets de archivos',
    'Community Forum'    => 'Foro comunitario',
    'Entry Feed'         => 'Sindicación de entradas',
    'Displays error, pending or confirmation message when submitting a entry.'
        => 'Muestra un mensaje de error, de pendiente o de confirmación al enviar una entrada.',
    'Popular Entry'   => 'Entrada popular',
    'Entry Table'     => 'Tabla de entradas',
    'Content Header'  => 'Cabecera de contenidos',
    'Category Groups' => 'Grupos de categorías',
    'Default Widgets' => 'Widgets predefinidos',

## addons/Community.pack/lib/MT/App/Community.pm
    'No login form template defined' =>
        'No hay ninguna plantilla de formulario definida',
    'Before you can sign in, you must authenticate your email address. <a href="[_1]">Click here</a> to resend the verification email.'
        => 'Antes de que pueda iniciar una sesión, debe autentificar su dirección de correo. <a href="[_1]">Haga clic aquí</a> para reenviar el correo de verificación.',
    'You are trying to redirect to external resources: [_1]' =>
        'Está intentando redireccionar a recursos externos: [_1]',
    'Successfully authenticated but signing up is not allowed.  Please contact system administrator.'
        => 'La identificación se ha producido con suceso pero la conexión ha sido rechazada.  Por favor contacte el administrador del sistema.',
    '(No email address)' => '(Sin dirección de correo)',
    'User \'[_1]\' (ID:[_2]) has been successfully registered.' =>
        'El usuario \'[_1]\' (ID:[_2]) se registró con éxito.',
    'Thanks for the confirmation.  Please sign in.' =>
        'Gracias por la confirmación. Por favor, inicie la sesión.',
    '[_1] registered to Movable Type.' =>
        '[_1] se registró en Movable Type.',
    'Login required' => 'Requerido inicio de sesión',
    'Title or Content is required.' =>
        'El título o contenido es obligatorio.',
    'Publish failed: [_1]' => 'Falló la publicación: [_1]',
    'System template entry_response not found in blog: [_1]' =>
        'La plantilla del sistema entry_response no se encontró en el blog: [_1]',
    'New entry \'[_1]\' added to the blog \'[_2]\'' =>
        'Añadida una nueva entrada \'[_1]\' al blog \'[_2]\'',
    'Id or Username is required' =>
        'Se necesita el Id o el nombre del usuario',
    'Unknown user' => 'Usuario desconocido',
    'All required fields must have valid values.' =>
        'Todos los campos obligatorios deben tener valores válidos.',
    'Recent Entries from [_1]' => 'Entradas recientes de [_1]',
    'Responses to Comments from [_1]' =>
        'Respuestas a los comentarios de [_1]',
    'Actions from [_1]' => 'Acciones de [_1]',

## addons/Community.pack/lib/MT/Community/CMS.pm
    'Movable Type was unable to write on the "Upload Destination". Please make sure that the folder is writable from the web server.'
        => 'Movable Type no pudo escribir en el "Destino de las transferencias". Por favor, asegúrese de que el servidor web puede escribir en el directorio.',

## addons/Community.pack/lib/MT/Community/Tags.pm
    'You used an \'[_1]\' tag outside of the block of MTIfEntryRecommended; perhaps you mistakenly placed it outside of an \'MTIfEntryRecommended\' container?'
        => 'Utilizó una etiqueta \'[_1]\' fuera del bloque MTIfEntryRecommended; ¿quizás la situó por error fuera de un contenedor \'MTIfEntryRecommended\'?',
    'Click here to recommend' =>
        'Haga clic aquí para hacer una recomendación',
    'Click here to follow' => 'Clic aquí para seguir a',
    'Click here to leave'  => 'Clic aquí para dejar de seguir a',

## addons/Community.pack/php/function.mtentryrecommendvotelink.php

## addons/Community.pack/templates/blog/about_this_page.mtml
    'This page contains a single entry by <a href="[_1]">[_2]</a> published on <em>[_3]</em>.'
        => 'Esta página contiene una sola entrada realizada por <a href="[_1]">[_2]</a> y publicada el <em>[_3]</em>.',

## addons/Community.pack/templates/blog/archive_index.mtml

## addons/Community.pack/templates/blog/archive_widgets_group.mtml
    'This is a custom set of widgets that are conditioned to serve different content based upon what type of archive it is included. More info: [_1]'
        => 'Conjunto personalizado de widgets creado para mostrar contenidos diferentes según el tipo de archivo que incluye. Más información: [_1]',

## addons/Community.pack/templates/blog/categories.mtml

## addons/Community.pack/templates/blog/category_archive_list.mtml

## addons/Community.pack/templates/blog/comment_detail.mtml

## addons/Community.pack/templates/blog/comment_form.mtml

## addons/Community.pack/templates/blog/comment_listing.mtml

## addons/Community.pack/templates/blog/comment_preview.mtml
    'Comment on [_1]' => 'Comentario en [_1]',

## addons/Community.pack/templates/blog/comment_response.mtml

## addons/Community.pack/templates/blog/comments.mtml
    'The data in #comments-content will be replaced by some calls to paginate script'
        => 'Los datos en #comments-content se reemplazarán por llamadas al script de paginación',

## addons/Community.pack/templates/blog/content_nav.mtml
    'Blog Home' => 'Incio - Blog',

## addons/Community.pack/templates/blog/current_category_monthly_archive_list.mtml

## addons/Community.pack/templates/blog/dynamic_error.mtml

## addons/Community.pack/templates/blog/entry.mtml

## addons/Community.pack/templates/blog/entry_create.mtml

## addons/Community.pack/templates/blog/entry_detail.mtml

## addons/Community.pack/templates/blog/entry_form.mtml
    'In order to create an entry on this blog you must first register.' =>
        'Para crear una entrada en este blog, primero debe registrarse.',
    q{You don't have permission to post.} =>
        q{No tiene permisos para publicar.},
    'Sign in to create an entry.' => 'Identifíquese para crear una entrada.',
    'Select Category...'          => 'Seleccione una categoría...',

## addons/Community.pack/templates/blog/entry_listing.mtml
    'Recently by <em>[_1]</em>' => 'Novedades por <em>[_1]</em>',

## addons/Community.pack/templates/blog/entry_metadata.mtml
    'Vote'  => 'Voto',
    'Votes' => 'Votos',

## addons/Community.pack/templates/blog/entry_response.mtml
    'Thank you for posting an entry.' => 'Gracias por publicar una entrada.',
    'Entry Pending'                   => 'Entrada pendiente',
    'Your entry has been received and held for approval by the blog owner.' =>
        'Su entrada ha sido recibida y está pendiente de aprobación por el propietario del blog.',
    'Entry Posted'                  => 'Entrada publicada',
    'Your entry has been posted.'   => 'La entrada ha sido publicada.',
    'Your entry has been received.' => 'La entrada ha sido recibida.',
    q{Return to the <a href="[_1]">blog's main index</a>.} =>
        q{Regresar al <a href="[_1]">índice principal del blog</a>.},

## addons/Community.pack/templates/blog/entry_summary.mtml

## addons/Community.pack/templates/blog/javascript.mtml

## addons/Community.pack/templates/blog/main_index.mtml

## addons/Community.pack/templates/blog/main_index_widgets_group.mtml
    'This is a custom set of widgets that are conditioned to only appear on the homepage (or "main_index"). More info: [_1]'
        => 'Este es un conjunto personalizado de widgets creados para aparecer solo en la página de inicio (o "main_index"). Más información: [_1]',

## addons/Community.pack/templates/blog/monthly_archive_list.mtml

## addons/Community.pack/templates/blog/openid.mtml

## addons/Community.pack/templates/blog/page.mtml

## addons/Community.pack/templates/blog/pages_list.mtml

## addons/Community.pack/templates/blog/powered_by.mtml

## addons/Community.pack/templates/blog/recent_assets.mtml

## addons/Community.pack/templates/blog/recent_comments.mtml
    '<a href="[_1]">[_2] commented on [_3]</a>: [_4]' =>
        '<a href="[_1]">[_2] comentó en [_3]</a>: [_4]',

## addons/Community.pack/templates/blog/recent_entries.mtml

## addons/Community.pack/templates/blog/search.mtml

## addons/Community.pack/templates/blog/search_results.mtml

## addons/Community.pack/templates/blog/sidebar.mtml

## addons/Community.pack/templates/blog/syndication.mtml

## addons/Community.pack/templates/blog/tag_cloud.mtml

## addons/Community.pack/templates/blog/tags.mtml

## addons/Community.pack/templates/blog/trackbacks.mtml

## addons/Community.pack/templates/forum/archive_index.mtml

## addons/Community.pack/templates/forum/category_groups.mtml
    'Forum Groups' => 'Grupos de los foros',
    'Last Topic: [_1] by [_2] on [_3]' =>
        'Último tema: [_1] by [_2] on [_3]',
    'Be the first to <a href="[_1]">post a topic in this forum</a>' =>
        'Sea el primero en <a href="[_1]">publicar un tema en este foro</a>',

## addons/Community.pack/templates/forum/comment_detail.mtml
    '[_1] replied to <a href="[_2]">[_3]</a>' =>
        '[_1] respondió a <a href="[_2]">[_3]</a>',

## addons/Community.pack/templates/forum/comment_form.mtml
    'Add a Reply' => 'Responder',

## addons/Community.pack/templates/forum/comment_listing.mtml

## addons/Community.pack/templates/forum/comment_preview.mtml
    'Reply to [_1]'         => 'Responder a [_1]',
    'Previewing your Reply' => 'Vista previa de la respuesta',

## addons/Community.pack/templates/forum/comment_response.mtml
    'Reply Submitted'               => 'Respuesta enviada',
    'Your reply has been accepted.' => 'Se ha aceptado su respuesta.',
    'Thank you for replying.'       => 'Gracias por responder.',
    'Your reply has been received and held for approval by the forum administrator.'
        => 'Su respuesta ha sido recibida y retenida para su aprobación por el administrador del foro.',
    'Reply Submission Error' => 'Error en el envío de la respuesta',
    'Your reply submission failed for the following reasons: [_1]' =>
        'El envío de la respuesta falló por alguna de las siguientes razones: [_1]',
    'Return to the <a href="[_1]">original topic</a>.' =>
        'Regresar al <a href="[_1]">tema original</a>.',

## addons/Community.pack/templates/forum/comments.mtml
    '1 Reply'    => '1 respuesta',
    '# Replies'  => '# respuestas',
    'No Replies' => 'Sin respuestas',

## addons/Community.pack/templates/forum/content_header.mtml
    'Start Topic' => 'Comenzar tema',

## addons/Community.pack/templates/forum/content_nav.mtml

## addons/Community.pack/templates/forum/dynamic_error.mtml

## addons/Community.pack/templates/forum/entry.mtml

## addons/Community.pack/templates/forum/entry_create.mtml
    'Start a Topic' => 'Comenzar un tema',

## addons/Community.pack/templates/forum/entry_detail.mtml

## addons/Community.pack/templates/forum/entry_form.mtml
    'Topic'           => 'Tema',
    'Select Forum...' => 'Seleccionar foro...',
    'Forum'           => 'Foro',

## addons/Community.pack/templates/forum/entry_listing.mtml

## addons/Community.pack/templates/forum/entry_metadata.mtml

## addons/Community.pack/templates/forum/entry_popular.mtml
    'Popular topics'          => 'Temas populares',
    'Last Reply'              => 'Última respuesta',
    'Permalink to this Reply' => 'Enlace permanente de esta respuesta',
    'By [_1]'                 => 'Por [_1]',

## addons/Community.pack/templates/forum/entry_response.mtml
    'Thank you for posting a new topic to the forums.' =>
        'Gracias por publicar un nuevo tema en los foros.',
    'Topic Pending' => 'Tema pendiente',
    'The topic you posted has been received and held for approval by the forum administrators.'
        => 'El tema que ha publicado se ha recibido y está pendiente de aprobación por parte de los administradores del foro.',
    'Topic Posted' => 'Tema publicado',
    'The topic you posted has been received and published. Thank you for your submission.'
        => 'El tema que envió se ha recibido y ya está publicado. Gracias por su aportación.',
    q{Return to the <a href="[_1]">forum's homepage</a>.} =>
        q{Regresar a la página de <a href="[_1]">inicio del foro</a>.},

## addons/Community.pack/templates/forum/entry_summary.mtml

## addons/Community.pack/templates/forum/entry_table.mtml
    'Recent Topics' => 'Temas recientes',
    'Replies'       => 'Respuestas',
    'Closed'        => 'Cerrado',
    'Post the first topic in this forum.' =>
        'Publica el primer tema en este foro.',

## addons/Community.pack/templates/forum/javascript.mtml
    'Thanks for signing in,' => 'Gracias por registrarse en,',
    '. Now you can reply to this topic.' =>
        '. Ahora puede contestar en este tema.',
    'You do not have permission to comment on this blog.' =>
        'No tiene permisos para comentar en este blog.',
    ' to reply to this topic.' => ' para responder a este tema.',
    ' to reply to this topic,' => ' para responder a este tema,',
    'or '                      => 'o ',
    'reply anonymously.'       => 'responder anónimamente.',

## addons/Community.pack/templates/forum/main_index.mtml
    'Forum Home' => 'Foro - Inicio',

## addons/Community.pack/templates/forum/openid.mtml

## addons/Community.pack/templates/forum/page.mtml

## addons/Community.pack/templates/forum/search_results.mtml
    'Topics matching &ldquo;[_1]&rdquo;' =>
        'Temas que coinciden con &ldquo;[_1]&rdquo;',
    'Topics tagged &ldquo;[_1]&rdquo;' =>
        'Temas etiquetados con &ldquo;[_1]&rdquo;',
    'Topics' => 'Temas',
    'By default, this search engine looks for all words in any order. To search for an exact phrase, enclose the phrase in quotes:'
        => 'Por defecto, este motor de búsqueda comprueba todas las palabras sin tener en cuenta el orden. Para buscar una frase exacta, encierre la frase entre comillas:',

## addons/Community.pack/templates/forum/sidebar.mtml

## addons/Community.pack/templates/forum/syndication.mtml
    'All Forums' => 'Todos los foros',
    '[_1] Forum' => 'Foro [_1]',

## addons/Community.pack/templates/global/email_verification_email.mtml
    'Thank you registering for an account to [_1].' =>
        'Gracias por registrar una cuenta en [_1].',
    'For your own security and to prevent fraud, we ask that you please confirm your account and email address before continuing. Once confirmed you will immediately be allowed to sign in to [_1].'
        => 'Por su propia seguridad y para prevenir fraudes, le solicitamos que confirme su cuenta y dirección de correo antes de continuar. Una vez confirmados, ya podrá iniciar una sesión en [_1].',
    'To confirm your account, please click on or cut and paste the following URL into a web browser:'
        => 'Para confirmar su cuenta, haga clic en (o copie y pegue) la URL en un navegador web:',
    q{If you did not make this request, or you don't want to register for an account to [_1], then no further action is required.}
        => q{Si no realizó esta petición, o no quiere registrar una cuenta en [_1], no se requiere ninguna otra acción.},
    'Thank you very much for your understanding.' =>
        'Gracias por su comprensión.',

## addons/Community.pack/templates/global/footer.mtml

## addons/Community.pack/templates/global/header.mtml
    'Blog Description' => 'Descripción del blog',

## addons/Community.pack/templates/global/javascript.mtml

## addons/Community.pack/templates/global/login_form.mtml
    'Not a member?&nbsp;&nbsp;<a href="[_1]">Sign Up</a>!' =>
        '¿No es usuario?&nbsp;&nbsp;¡<a href="[_1]">Inscríbase</a>!',

## addons/Community.pack/templates/global/login_form_module.mtml
    'Logged in as <a href="[_1]">[_2]</a>' =>
        'Identificado como <a href="[_1]">[_2]</a>',
    'Logout'          => 'Cerrar sesión',
    'Hello [_1]'      => 'Hola [_1]',
    'Forgot Password' => 'Recuperar la contraseña',
    'Sign up'         => 'Registro',

## addons/Community.pack/templates/global/navigation.mtml

## addons/Community.pack/templates/global/new_entry_email.mtml
    q{A new entry '[_1]([_2])' has been posted on your blog [_3].} =>
        q{Se ha publicado una nueva entrada '[_1]([_2])' en su blog [_3].},
    'Author name: [_1]'     => 'Nombre del autor: [_1]',
    'Author nickname: [_1]' => 'Pseudónimo del autor: [_1]',
    'Title: [_1]'           => 'Título: [_1]',
    'Edit entry:'           => 'Editar entrada:',

## addons/Community.pack/templates/global/new_password.mtml

## addons/Community.pack/templates/global/new_password_reset_form.mtml
    'Go Back (x)' => 'Volver',

## addons/Community.pack/templates/global/profile_edit_form.mtml
    'Go <a href="[_1]">back to the previous page</a> or <a href="[_2]">view your profile</a>.'
        => '<a href="[_1]">Regresar a la página anterior</a> o <a href="[_2]">vea su perfil</a>.',

## addons/Community.pack/templates/global/profile_error.mtml
    'ERROR MSG HERE' => 'MENSAJE DE ERROR AQUÍ',
    'Go Back'        => 'Ir atrás',

## addons/Community.pack/templates/global/profile_feed.mtml
    'Posted [_1] to [_2]'       => '[_1] publicado en [_2]',
    'Commented on [_1] in [_2]' => 'Comentó en [_1] en [_2]',
    'Voted on [_1] in [_2]'     => 'Votó en [_1] en [_2]',
    '[_1] voted on <a href="[_2]">[_3]</a> in [_4]' =>
        '[_1] votó en <a href="[_2]">[_3]</a> en [_4]',

## addons/Community.pack/templates/global/profile_view.mtml
    'User Profile'                  => 'Perfil del usuario',
    'Recent Actions from [_1]'      => 'Acciones recientes de [_1]',
    'You are following [_1].'       => 'Estás siguiendo a [_1]',
    'Unfollow'                      => 'Dejar de seguir',
    'Follow'                        => 'Seguir',
    'You are followed by [_1].'     => 'Te sigue [_1]',
    'You are not followed by [_1].' => 'No te sigue [_1]',
    'Website:'                      => 'Web:',
    'Recent Actions'                => 'Acciones recientes',
    'Comment Threads'               => 'Hilos de comentarios',
    'Commented on [_1]'             => 'Comentó en [_2]',
    'Favorited [_1] on [_2]'        => 'Marcó como favorito [_1] en [_2]',
    'No recent actions.'            => 'Ninguna acción reciente',
    '[_1] commented on '            => '[_1] comentó en',
    'No responses to comments.'     => 'Sin respuestas a comentarios.',
    'Not following anyone'          => 'No sigue a nadie',
    'Not being followed'            => 'Sin seguidores',

## addons/Community.pack/templates/global/register_confirmation.mtml
    'Authentication Email Sent' => 'Correo de autentificación enviado.',
    'Profile Created'           => 'Perfil creado',

## addons/Community.pack/templates/global/register_form.mtml

## addons/Community.pack/templates/global/register_notification_email.mtml
    q{This email is to notify you that a new user has successfully registered on the blog '[_1]'. Listed below you will find some useful information about this new user.}
        => q{Este correo electrónico es una notificaión  para informarle que un nuevo usuario ha sido enregistrado con succeso en el blog '[_1]'. Abajo usted encontratá enumeradas algunas informaciones útiles sobre este nuevo usuario.},

## addons/Community.pack/templates/global/search.mtml

## addons/Community.pack/templates/global/signin.mtml
    'You are signed in as <a href="[_1]">[_2]</a>' =>
        'Está identificado como <a href="[_1]">[_2]</a>',
    'You are signed in as [_1]' => 'Está identificado como [_1]',
    'Edit profile'              => 'Editar Perfil',
    'Not a member? <a href="[_1]">Register</a>' =>
        '¿No es miembro? <a href="[_1]">Registrarse</a>',

## addons/Community.pack/tmpl/cfg_community_prefs.tmpl
    'Community Settings'       => 'Configuración de la comunidad',
    'Anonymous Recommendation' => 'Recomendación anónima',
    'Check to allow anonymous users (users not logged in) to recommend discussion.  IP address is recorded and used to identify each user.'
        => 'Active esta opción para permitir que los usuarios anónimos (aquellos que no han iniciado una sesión) puedan recomendar debates. Las direcciones IP se registran y se utilizan para identificar a cada usuario.',
    'Allow anonymous user to recommend' =>
        'Permitir que los usuarios anónimos hagan recomendaciones',
    'Junk Filter' => 'Filtro basura',
    'If enabled, all moderated entries will be filtered by Junk Filter.' =>
        'Si se activa, todas las entradas moderadas se filtrarán por el Filtro de basura.',
    'Save changes to blog (s)' => 'Guardar los cambios en el blog (s)',

## addons/Community.pack/tmpl/widget/blog_stats_registration.mtml
    'Recent Registrations' => 'Registros recientes',
    'default userpic'      => 'avatar predefinido',
    'You have [quant,_1,registration,registrations] from [_2]' =>
        'Tiene un [quant,_1,registro,registros] en [_2]',

## addons/Community.pack/tmpl/widget/most_popular_entries.mtml
    'There are no popular entries.' => 'No hay entradas populares.',

## addons/Community.pack/tmpl/widget/recent_submissions.mtml

## addons/Community.pack/tmpl/widget/recently_scored.mtml
    'There are no recently favorited entries.' =>
        'No hay recomendaciones recientes de entradas.',

);

1;
