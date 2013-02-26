/* Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved
 * This file is combined from multiple sources.  Consult the source files for their
 * respective licenses and copyrights.
 */;(function($){MT.EditorManager=function(){this.init.apply(this,arguments);};$.extend(MT.EditorManager,{editors:{},editorsForFormat:{},map:{},defaultWrapTag:'div',defaultWrapClass:'mt-editor-manager-wrap',register:function(id,editor){var thisConstructor=this;this.editors[id]=editor;$.each(editor.formatsForCurrentContext(),function(){if(!thisConstructor.editorsForFormat[this]){thisConstructor.editorsForFormat[this]=[];}
thisConstructor.editorsForFormat[this].push({id:id,editor:editor});});editor.onRegister(id);},updateMap:function(map){$.extend(this.map,map);},toMode:function(format){var wysiwygs={wysiwyg:1,richtext:1};return wysiwygs[format]?'wysiwyg':'source';},_findEditorClass:function(format){var thisConstructor=this;if(this.map[format]){var found=null;$.each(this.editorsForFormat[format]||[],function(){if(this.id==thisConstructor.map[format]){found=this;return false;}});if(found){return found;}}
if(this.editorsForFormat[format]){return this.editorsForFormat[format][0];}
else{return false;}},editorClass:function(format){return this._findEditorClass(format)||this._findEditorClass(this.toMode(format));},insertContent:function(html,field){$('#'+field).data('mt-editor')
.insertContent(html);}});$.extend(MT.EditorManager.prototype,{init:function(id,options){var manager=this;this.id=id;var opt=this.options=$.extend({format:'richtext',wrap:false,wrapTag:this.constructor.defaultWrapTag,wrapClass:this.constructor.defaultWrapClass},options);this.editors={};this.parentElement=null;if(this.options['wrap']){this.parentElement=$('#'+id)
.wrap('<'+opt['wrapTag']+' class="'+opt['wrapClass']+'" />')
.parent();}
this.currentEditor=this.editorInstance(this.options['format']);this.currentEditor.initOrShow(this.options['format']);$('#'+id).data('mt-editor',this);$(window).bind('pre_autosave',function(){manager.save();});},editorInstance:function(format){var editorClass=this.constructor.editorClass(format);if(!this.editors[editorClass.id]){this.editors[editorClass.id]=new editorClass.editor(this.id,this);}
return this.editors[editorClass.id];},setMode:function(mode){this.setFormat(mode);},setFormat:function(format){if(format==this.options['format']){return;}
this.options['format']=format;var editor=this.editorInstance(format);if(editor===this.currentEditor){this.currentEditor.setFormat(format);}
else{var content=this.currentEditor.getContent();var height=this.currentEditor.getHeight();this.currentEditor.hide();this.currentEditor=editor;this.currentEditor.initOrShow(format);this.currentEditor.setContent(content);this.currentEditor.setHeight(height);}},hide:function(){if(this.parentElement){this.parentElement.hide();}},show:function(){if(this.parentElement){this.parentElement.show();}},ignoreSetDirty:function(callback){this.currentEditor.ignoreSetDirty(callback);},clearDirty:function(){this.currentEditor.clearDirty();}});$.each(['focus','save','getContent','setContent','insertContent','getHeight','setHeight','resetUndo','domUpdated'],function(){var method=this;MT.EditorManager.prototype[method]=function(){return this.currentEditor[method].apply(this.currentEditor,arguments);};});})(jQuery);;(function($){MT.EditorCommand=function(editor){this.editor=this.e=editor;};$.extend(MT.EditorCommand.prototype,{isSupported:function(command){return true;},editLink:function(linkElement){this.createLink(linkElement.getAttribute('href'),true,linkElement);},createLink:function(url,textSelected,anchor){var linkedText="";if(!url)
url="http://";if(typeof(textSelected)=='undefined')
textSelected=this.e.getSelectedText();url=prompt(Editor.strings.enterLinkAddress,url);if(!url)
return false;if(!textSelected)
linkedText=prompt(Editor.strings.enterTextToLinkTo,"");this.insertLink({url:url,linkedText:linkedText,anchor:anchor});},initLinkDataBagUrl:function(dataBag){if(!dataBag||!dataBag.url||!dataBag.url.trim())
return null;dataBag.url=dataBag.url.trim();return dataBag;},insertLink:function(dataBag){dataBag=this.initLinkDataBagUrl(dataBag);if(!dataBag)
return;if(!dataBag.anchor){if(dataBag.linkedText){var html="<a href='"+dataBag.url+"'>"+dataBag.linkedText+"</a>";this.editor.insertContent(html);}else{this.execCommand("createLink",false,dataBag.url);}}else{dataBag.anchor.href=dataBag.url;return dataBag.anchor;}},editEmail:function(linkElement){this.createEmailLink(linkElement.href,true,linkElement);},mailtoRegexp:/^mailto:/i,createEmailLink:function(url,textSelected,anchor){var linkedText="";if(!url)
url="";if(typeof(textSelected)=='undefined')
textSelected=this.e.getSelectedText();url=url.replace(this.mailtoRegexp,"");url=prompt(Editor.strings.enterEmailAddress,url);if(!url)
return false;if(!textSelected)
linkedText=prompt(Editor.strings.enterTextToLinkTo,"");this.insertLink({url:"mailto:"+url,linkedText:linkedText,anchor:anchor});},focus:function(){this.editor.focus();}});})(jQuery);;(function($){MT.EditorCommand.WYSIWYG=function(editor){MT.EditorCommand.apply(this,arguments);this.doc=editor.getDocument();};$.extend(MT.EditorCommand.WYSIWYG.prototype,MT.EditorCommand.prototype,{mutateFontSize:function(element,bigger){var goSmaller=0.8;var goBigger=1.25;var biggest=Math.pow(goBigger,3);var smallest=Math.pow(goSmaller,3);var defaultSize=bigger?goBigger+"em":goSmaller+"em";var fontSize=element.style.fontSize.match(/([\d\.]+)(%|em|$)/);if(fontSize==null||isNaN(fontSize[1]))
return defaultSize;var size;if(fontSize[2]=="%")
size=fontSize[1]/100;else if(fontSize[2]=="em"||fontSize[2]=="")
size=fontSize[1];var factor=bigger?goBigger:goSmaller;size=size*factor;if(size>biggest)
size=biggest;else if(size<smallest)
size=smallest;return size+"em";},changeFontSizeOfSelection:function(doc,bigger){var bogus="-editor-proxy";doc.execCommand("fontName",false,bogus);var elements=null;elements=doc.getElementsByTagName("font");for(var i=0;i<elements.length;i++){var element=elements[i];if(element.face==bogus){element.removeAttribute("face");element.style.fontSize=this.mutateFontSize(element,bigger);return;}}
elements=doc.getElementsByTagName("span");for(var i=0;i<elements.length;i++){var element=elements[i];if(element.style.fontFamily==bogus){element.style.fontFamily='';element.style.fontSize=this.mutateFontSize(element,bigger);return;}}},execCommand:function(command,userInterface,argument){var func=this.commands[command];if(func){func.apply(this,[command,userInterface,argument]);}
else{this.doc.execCommand(command,userInterface,argument);}
this.editor.setDirty();},commands:{}});$.extend(MT.EditorCommand.WYSIWYG.prototype.commands,{fontSizeSmaller:function(command,userInterface,argument){this.changeFontSizeOfSelection(this.doc,false);},fontSizeLarger:function(command,userInterface,argument){this.changeFontSizeOfSelection(this.doc,true);},insertLink:function(command,userInterface,argument){if(argument['anchor']){this.editLink(argument['anchor']);}
else{this.createLink(null,argument['textSelected']);}},insertEmail:function(command,userInterface,argument){if(argument['anchor']){this.editEmail(argument['anchor']);}
else{this.createEmailLink(null,argument['textSelected']);}}});})(jQuery);;(function($){MT.EditorCommand.Source=function(editor){MT.EditorCommand.apply(this,arguments);this.format='default';};$.extend(MT.EditorCommand.Source.prototype,MT.EditorCommand.prototype,{setFormat:function(format){this.format=format;this.commandStates={};},isSupported:function(command,format,feature){var format=format||this.format;if(!this.commands[format]){format='default';}
if(feature){command+='-'+feature;}
return this.commands[format][command];},execCommand:function(command,userInterface,argument,options){var text=this.e.getSelectedText();if(!defined(text))
text='';var format=this.format;if(!this.commands[format]){format='default';}
var func=this.commands[format][command];if(func){func.apply(this,[command,userInterface,argument,text,options]);}
return this.editor.setDirty();},commandStates:{},isStateActive:function(command){return this.commandStates[command]?true:false;},execEnclosingCommand:function(command,open,close,text,selectedCallback){if(!text){if(!this.isStateActive(command)){this.e.setSelection(open);this.commandStates[command]=true;}
else{this.e.setSelection(close);this.commandStates[command]=false;}}
else{if(selectedCallback){selectedCallback.apply(this,[]);}
else{this.e.setSelection(open+text+close);}}},execLinkCommand:function(command,open,close,text){var selection;this.e.setSelection(open);if(text){this.e.setSelection(text);}
else{selection=this.e.saveSelection();}
this.e.setSelection(close);if(selection){this.e.restoreSelection(selection);}},commands:{}});MT.EditorCommand.Source.prototype.commands['default']={fontSizeSmaller:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<small>','</small>',text);},fontSizeLarger:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<big>','</big>',text);},bold:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<strong>','</strong>',text);},italic:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<em>','</em>',text);},underline:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<u>','</u>',text);},strikethrough:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<strike>','</strike>',text);},insertLink:function(command,userInterface,argument,text){this.createLink();},insertEmail:function(command,userInterface,argument,text){this.createLink();},createLink:function(command,userInterface,argument,text,options){var open='<a href="'+argument+'"';if(options){if(options['target']){open+=' target="'+options['target']+'"';}
if(options['title']){open+=' title="'+options['title']+'"';}}
open+='>';this.execLinkCommand(command,open,'</a>',text);},'createLink-target':true,indent:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<blockquote>','</blockquote>',text);},blockquote:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<blockquote>','</blockquote>',text);},insertUnorderedList:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<ul>','</ul>',text);},insertOrderedList:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<ol>','</ol>',text);},insertListItem:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<li>','</li>',text);},justifyLeft:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<div style="text-align: left;">','</div>',text);},justifyCenter:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<div style="text-align: center;">','</div>',text);},justifyRight:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<div style="text-align: right;">','</div>',text);}};MT.EditorCommand.Source.prototype.commands['markdown']=MT.EditorCommand.Source.prototype.commands['markdown_with_smartypants']={bold:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'**','**',text);},italic:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'*','*',text);},insertLink:function(command,userInterface,argument,text){this.createLink();},insertEmail:function(command,userInterface,argument,text){this.createLink();},createLink:function(command,userInterface,argument,text,options){var close="]("+argument;if(options){if(options['title']){close+=' "'+options['title']+'"';}}
close+=')';this.execLinkCommand(command,"[",close,text);},indent:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]="> "+list[i];this.e.setSelection(list.join("\n"));},blockquote:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]="> "+list[i];this.e.setSelection(list.join("\n"));},insertUnorderedList:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]=" - "+list[i];this.e.setSelection("\n"+list.join("\n"));},insertOrderedList:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]=" "+(i+1)+".  "+list[i];this.e.setSelection("\n"+list.join("\n"));}};MT.EditorCommand.Source.prototype.commands['textile_2']={bold:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'**','**',text);},italic:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'_','_',text);},strikethrough:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'-','-',text);},insertLink:function(command,userInterface,argument,text){this.createLink();},insertEmail:function(command,userInterface,argument,text){this.createLink();},createLink:function(command,userInterface,argument,text,options){var close='';if(options){if(options['title']){close+='('+options['title']+')';}}
close+='":'+argument;this.execLinkCommand(command,'"',close,text);},indent:function(command,userInterface,argument,text){this.e.setSelection("bq. "+text);},blockquote:function(command,userInterface,argument,text){this.e.setSelection("bq. "+text);},underline:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<u>','<u>',text);},insertUnorderedList:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]="* "+list[i];this.e.setSelection("\n"+list.join("\n"));},insertOrderedList:function(command,userInterface,argument,text){var list=text.split(/\r?\n/);for(var i=0;i<list.length;i++)
list[i]="# "+list[i];this.e.setSelection("\n"+list.join("\n"));},justifyLeft:function(command,userInterface,argument,text){this.e.setSelection("p< "+text);},justifyCenter:function(command,userInterface,argument,text){this.e.setSelection("p= "+text);},justifyRight:function(command,userInterface,argument,text){this.e.setSelection("p> "+text);},fontSizeSmaller:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<small>','<small>',text);},fontSizeLarger:function(command,userInterface,argument,text){this.execEnclosingCommand(command,'<big>','<big>',text);}};})(jQuery);;(function($){$.extend(MT.App,{defaultEditorStrategy:'multi',setDefaultEditorStrategy:function(strategy){this.defaultEditorStrategy=strategy;},getDefaultEditorStrategy:function(){return this.defaultEditorStrategy;},newEditorStrategy:function(strategy){if(!strategy){strategy=this.defaultEditorStrategy;}
return MT.App.EditorStrategy.newInstance(strategy);}});MT.App.prototype=$.extend({},MT.App.prototype,{initEditor:function(){var format=$('#convert_breaks').val();if(!MT.EditorManager.editorClass('wysiwyg')){$('#convert_breaks option[value="richtext"]').remove();format=$('#convert_breaks').val();}
if(!this.editorStrategy){this.editorStrategy=this.constructor.newEditorStrategy();}
this.editorIds=$.map($('#editor-content textarea'),function(elm,i){return elm.id;});this.editorStrategy.create(this,this.editorIds,format);this.editorStrategy.set(this,this.editorIds[0]);},setEditorIframeHTML:function(){this.editor.setFormat('richtext');},saveHTML:function(resetChanged){this.editorStrategy.save(this);if(resetChanged){this.clearDirty();this.editor.clearDirty();}},setEditor:function(id){this.editorStrategy.set(this,'editor-input-'+id);},insertHTML:function(html,field){MT.EditorManager.insertContent(html,field);}});})(jQuery);;(function($){MT.Editor=function(id,manager){this.id=id;this.manager=manager;this.initialized=false;this.editor=null;};$.extend(MT.Editor,{ensureInitializedMethods:['setFormat','setContent','insertContent','hide','clearDirty','setHeight','resetUndo','domUpdated'],defaultCommonOptions:{body_class_list:[],content_css_list:[]},updateDefaultCommonOptions:function(options){$.extend(this.defaultCommonOptions,options);},isMobileOSWYSIWYGSupported:function(){return true;},formats:function(){return['wysiwyg','source'];},formatsForCurrentContext:function(){if(!this.isMobileOSWYSIWYGSupported()&&navigator.userAgent.match(/Android|i(Phone|Pad|Pod)/)){return $.grep(this.formats(),function(format){return format!='wysiwyg';});}
else{return this.formats();}},setupEnsureInitializedMethods:function(names){var klass=this;$.each(names,function(){var original=klass.prototype[this];klass.prototype[this]=function(){this.ensureInitialized(original,arguments);};});},onRegister:function(id){this.setupEnsureInitializedMethods(this.ensureInitializedMethods);}});$.extend(MT.Editor.prototype,{isIgnoreAppSetDirty:false,init:function(commonOptions){this.commonOptions=$.extend({},this.constructor.defaultCommonOptions,commonOptions);this.initialized=true;this.initEditor.apply(this,arguments);},initOrShow:function(format){if(!this.initialized){this.init(format);}
else{this.show();this.setFormat(format);}},ensureInitialized:function(func,args){var instance=this;if(instance.editor){func.apply(instance,args);}
else{var id=setInterval(function(){if(instance.editor){clearInterval(id);func.apply(instance,args);}},100);}},setDirty:function(){this.setAppDirty.apply(this,arguments);},setAppDirty:function(){if(!this.isIgnoreAppSetDirty&&window.app){window.app.setDirty.apply(window.app,arguments);}},ignoreSetDirty:function(callback){var saved=this.isIgnoreAppSetDirty;this.isIgnoreAppSetDirty=true;callback.apply(this,[]);this.isIgnoreAppSetDirty=saved;},clearDirty:function(){},initEditor:function(id,format,opts,callback){},setFormat:function(){},domUpdated:function(){}});$.each(['show','hide','focus','save','getContent','setContent','insertContent','getHeight','setHeight','resetUndo'],function(){var method=this;MT.Editor.prototype[method]=function(){return this.editor?this.editor[method]():null;};});})(jQuery);;(function($){MT.App.EditorStrategy=function(){};$.extend(MT.App.EditorStrategy,{newInstance:function(name){name=name.slice(0,1).toUpperCase()+name.slice(1).toLowerCase();var c=this[name];return new c();}});$.extend(MT.App.EditorStrategy.prototype,{create:function(app,ids,format){},set:function(app,id){},save:function(app){}});})(jQuery);;(function($){var ES=MT.App.EditorStrategy;ES.Single=function(){ES.apply(this,arguments)};$.extend(ES.Single.prototype,ES.prototype,{create:function(app,ids,format){var id=ids.join('-');while($('#'+id).length>0){id+='-dummy';}
this.dummy_textarea=$('<textarea />')
.attr('id',id)
.insertBefore('#'+ids[0]);app.editor=new MT.EditorManager(id,{format:format});},set:function(app,id){var key='target_textarea';var strategy=this;var target=this.dummy_textarea.data(key);if(target){var content=app.editor.getContent();target.val(content);target.attr('name',strategy.dummy_textarea.attr('name'));strategy.dummy_textarea.removeAttr('name');}
target=$('#'+id);this.dummy_textarea.attr('name',target.attr('name'));target.removeAttr('name');app.editor.ignoreSetDirty(function(){app.editor.setContent(target.val());app.editor.clearDirty();});app.editor.resetUndo();this.dummy_textarea.data(key,target);},save:function(){app.editor.save();}});})(jQuery);;(function($){var ES=MT.App.EditorStrategy;ES.Multi=function(){ES.apply(this,arguments)};$.extend(ES.Multi.prototype,ES.prototype,{create:function(app,ids,format){app.editors={};$.each(ids,function(){$('#'+this).show();app.editors[this]=new MT.EditorManager(this,{format:format,wrap:true});var setFormat=app.editors[this]['setFormat'];app.editors[this]['setFormat']=function(format){$.each(app.editors,function(){setFormat.apply(this,[format]);});};});},set:function(app,id){var strategy=this;if(app.editor){var height=app.editor.getHeight();strategy._setWithHeight(app,id,height);}
else{strategy._setWithHeight(app,id,null);}},_setWithHeight:function(app,id,height){$(app.editorIds).each(function(){if(id==this){app.editors[this].show();app.editor=app.editors[this];if(height){app.editor.setHeight(height);}}
else{app.editors[this].hide();}});},save:function(){app.editor.save();}});})(jQuery);;(function($){var ES=MT.App.EditorStrategy;ES.Separator=function(){ES.apply(this,arguments)};$.extend(ES.Separator.prototype,ES.prototype,{create:function(app,ids,format){this.ids=ids;var id=ids.join('-');while($('#'+id).length>0){id+='-dummy';}
this.dummy_textarea=$('<textarea />')
.attr('id',id)
.insertBefore('#'+ids[0]);app.editor=new MT.EditorManager(id,{format:format});var content=$.map(ids,function(id,index){var value=$('#'+id).val();if(!value||value==''){value='<p><br /></p>';}
return value;}).join('<hr class="movable-type-editor-separator" />');app.editor.ignoreSetDirty(function(){app.editor.setContent(content);});$('#editor-header .tab').css({visibility:'hidden'});},save:function(app){var strategy=this;var content=app.editor.getContent();var contents=content.split(/<hr[^>]*class=['"]?movable-type-editor-separator['"]?[^>]*>/i);$.each(strategy.ids,function(i){var value=contents[i];if(value.match(/^\s*<p><br[^>]*><\/p>\s*$/)){value='';}
$('#'+this).val(value);});}});})(jQuery);;(function($){MT.Editor.Source=function(id){var editor=this;MT.Editor.apply(this,arguments);this.editor=editor;this.$textarea=$('#'+id);this.textarea=this.$textarea.get(0);this.range=null;var focused=false;this.$textarea
.keydown(function(){editor.saveSelection();editor.setDirty();})
.keyup(function(){editor.saveSelection();})
.focus(function(){focused=true;})
.blur(function(){focused=false;});$.each(['mouseup','touchend'],function(index,event){$(document).bind(event,function(){if(focused){editor.saveSelection();}});});};$.extend(MT.Editor.Source,MT.Editor,{ensureInitializedMethods:[],formats:function(){return['source'];}});$.extend(MT.Editor.Source.prototype,MT.Editor.prototype,{save:function(){return'';},getContent:function(){return this.textarea.value;},setContent:function(content){return this.textarea.value=content;},clearUndo:function(){return'';},focus:function(){this.textarea.focus();},getHeight:function(){return this.$textarea.height();},setHeight:function(height){this.$textarea.height(height);},hide:function(){this.$textarea.hide();},insertContent:function(content){this.setSelection(content);},getSelection:function(){var w=window;return w.getSelection?w.getSelection():w.document.selection;},getSelectedText:function(){var selection=this.getSelection();if(selection.createRange){var range=this.range;if(!range){this.focus();range=selection.createRange();}
return range.text;}else{var length=this.textarea.textLength;var start=this.selectionStart||this.textarea.selectionStart;var end=this.selectionEnd||this.textarea.selectionEnd;return this.textarea.value.substring(start,end);}},setSelection:function(txt,select_inserted_content){var el=this.textarea;var selection=this.getSelection();if(selection.createRange){var range=this.range;if(!range){this.focus();range=selection.createRange();}
range.text=txt;range.select();}else{var scrollTop=el.scrollTop;var length=el.textLength;var start=this.selectionStart||el.selectionStart;var end=this.selectionEnd||el.selectionEnd;el.value=el.value.substring(0,start)+txt+el.value.substr(end,length);if(select_inserted_content){el.selectionStart=start;el.selectionEnd=start+txt.length;}
else{el.selectionStart=start+txt.length;el.selectionEnd=start+txt.length;}
el.scrollTop=scrollTop;}
if(!select_inserted_content){this.saveSelection();}
this.focus();},saveSelection:function(){var selection=this.getSelection();var data={};if(selection.createRange){data.range=this.range=selection.createRange().duplicate();}
else{data.selectionStart=this.selectionStart=this.textarea.selectionStart;data.selectionEnd=this.selectionEnd=this.textarea.selectionEnd;}
return data;},restoreSelection:function(data){if(!data){data=this;}
if(!data.range&&!data.selectionStart){return;}
var selection=this.getSelection();if(selection.createRange){data.range.select();}
else{this.textarea.selectionStart=data.selectionStart;this.textarea.selectionEnd=data.selectionEnd;}}});})(jQuery);