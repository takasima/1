/*============================================================**
        for edit page
**============================================================*/

App.singletonConstructor =
MT.App = new Class( MT.App, {
    initEditor: function() {
        if ( this.constructor.Editor && DOM.getElement( "editor-content" ) ) {
            
            var mode = DOM.getElement( "convert_breaks" );
            DOM.addEventListener( mode, "change", this.getIndirectEventListener( "setTextareaMode" ) );
        
            /* special case */
            window.cur_text_format = mode.value;
        
            this.editorMode = ( mode.value == "richtext" ) ? "iframe" : "textarea";
            
            this.editor = this.addComponent( new MT.App.Editor( "editor-content", this.editorMode ) );
            this.editor.textarea.setTextMode( mode.value );
        
            this.editorInput = {
                content: DOM.getElement( "editor-input-content" ),
                extended: DOM.getElement( "editor-input-extended" )
            };
        
            if ( this.editorInput.content.value ) {
                if(tinymce_editor_edit.format != 'richtext'){
                    this.editor.setHTML( this.editorInput.content.value );
                }
            }
        }
    },
    setEditor: function(name) {
        this.saveHTML( false );
        this.currentEditor = name;
        if(tinymce_editor_edit.format != 'richtext'){
            this.editor.setHTML( this.editorInput[ this.currentEditor ].value );
        }else{
            tinymce_editor_edit.change(name);
        }
    },
    saveHTML: function( resetChanged ) {
        if(tinymce_editor_edit.format != 'richtext'){
            if ( !this.editor ){
                return;
            }
            //this.fixHTML();
            this.editorInput[ this.currentEditor ].value = this.editor.getHTML();
            
            if ( resetChanged ) {
                this.clearDirty();
            }
        }else{
            tinymce_editor_edit.save(this.editorInput[ this.currentEditor ]);
            if ( resetChanged ) {
                this.clearDirty();
            }
        }
    },
    setTextareaMode: function( event ) {
        tinymce_editor_edit.check_format();
        if(tinymce_editor_edit.format != 'richtext'){
            this.editor.textarea.setTextMode( event.target.value );
        }
    }
} );

/*============================================================**
        make object
**============================================================*/

tinymce_editor_edit = new Object();

/*============================================================**
        tinymce_editor_edit.check_format
**============================================================*/

tinymce_editor_edit.check_format = function(first_load){
    tinymce_editor_edit.format = jQuery('#convert_breaks').val();
    if(tinymce_editor_edit.format == 'richtext'){
        if(first_load){
            jQuery('#editor-content-textarea').val(jQuery('#editor-input-content').val());
        }
        
        jQuery('#editor-content-toolbar').hide();
        tinymce_editor.show(jQuery('#editor-content-textarea'));
    }else{
        jQuery('#editor-content-toolbar').show();
        tinymce_editor.remove(jQuery('#editor-content-textarea'));
    }
}


/*============================================================**
        tinymce_editor_edit.change
**============================================================*/
tinymce_editor_edit.change = function(mode){
    var target = '#editor-input-' + mode;
    var val = jQuery(target).val();
    tinymce_editor.ed['editor-content-textarea'].execCommand('mceSetContent', false, val);
}

/*============================================================**
        tinymce_editor_edit.save
**============================================================*/
tinymce_editor_edit.save = function(to){
    var editorHTML = tinymce_editor.ed['editor-content-textarea'].getContent();
    to.value = editorHTML;
}

/*============================================================**
        overwrite
**============================================================*/

function changedTextFormat() {
  var form = this.form;
  var option = this.options[this.selectedIndex].value;
  /*
  if ((cur_text_format != 'richtext') && (option == 'richtext')) {
      // warn user that changing to richtext is not reversible (easily)
      if (!confirm(tinymce_editor.trans['Are_you_sure_you_want_to_use_the_Rich_Text_editor'])) {
          // revert selection
          for (var i = 0; i < this.options.length; i++) {
              if (this.options[i].value == cur_text_format)
                  this.selectedIndex = i;
          }
          app.editor.focus();
          return;
      }
  }
  */
  var s = document.forms['entry_form'].convert_breaks;
  var key = s.options[s.selectedIndex].value;
  if (url = docs[key]) {
      if (url.indexOf('http://') == -1)
          url = HelpBaseURI + url;
      TC.removeClassName(getByID('formatting-help-link'), 'disabled');
  } else {
      TC.addClassName(getByID('formatting-help-link'), 'disabled');
  }

  if (cur_text_format == 'richtext') {

      var html = jQuery('#editor-content-textarea').val();
      jQuery('#editor-content-iframe').contents().find('body').html(html);

      // changing to plaintext editor
      TC.addClassName(TC.elementOrId("editor-content"), "editor-plaintext");
      orig_text_format = cur_text_format = option;
      app.editor.setMode('textarea');
      // app.editor.focus();
  } else if (option == 'richtext') {
      app.saveHTML(false);
      // changing to richtext editor
      // convert existing format to richtext
      var param = {
          '__mode': 'convert_to_html',
          'text': form.text.value,
          'text_more': form.text_more.value,
          'format': orig_text_format
      };
      var params = {
          uri: '<mt:var name="script_url">', method: 'POST',
              arguments: param, load: convertedText
      };
      // TC.Client.call(params); //BUG:Firefox4
  } else {
      orig_text_format = cur_text_format = option;
      // app.editor.focus();
  }
}

/*============================================================**
        load
**============================================================*/
jQuery(function(){
    tinymce_editor_edit.check_format('first_load');
})