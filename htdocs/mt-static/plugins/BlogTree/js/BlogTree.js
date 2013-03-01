var BlogTree ={
    set_tree: function(trgt,url){
        jQuery('#' + trgt).jstree({
            core : {
                'animation': 0
            },
            'plugins': ['themes','html_data','crrm'],
            'html_data': {
                'ajax': {
                    'url': url,
                    'data': function (n){
                        var d_class = '';
                        var d_id = '';
                        if(n.attr){
                            var id_base = n.attr('id').split('_');
                            d_class = id_base[0]
                            d_id = id_base[1];
                        }
                        return {
                            'class': d_class,
                            'id' : d_id,
                            '_' : (new Date()).getTime()
                        }
                    },
                    success: function(data){
                        
                    },
                    error: function(){
                        
                    }
                }
            }
        })
        .bind('loaded.jstree', function (event,data){
            // BlogTree.set_event(event,data,trgt)
        })
        .bind('load_node.jstree', function (event,data){
            BlogTree.set_event(event,data,trgt)
        })
    },
    set_event: function(event,data,trgt){
        BlogTree.toggle_meta(data);
        BlogTree.folder_opener(data,trgt);
        BlogTree.set_icon_active(data);
        BlogTree.set_more(data,trgt);
    },
    toggle_meta: function(data){
        if(data.args[0] == -1){
            var trgt = data.inst.get_container().find('li');
        }else{
            var trgt = data.args[0].find('li');
        }
        trgt.unbind('mouseover');
        trgt.mouseover(
            function(e){
                e.stopPropagation();
                jQuery(this).addClass('show_meta');
                jQuery(this).parents('.show_meta').removeClass('show_meta');
            }
        )
        trgt.unbind('mouseout');
        trgt.mouseout(
            function(e){
                jQuery(this).removeClass('show_meta');
            }
        )
    },
    folder_opener: function(data,trgt){
        if(data.args[0] == -1){
            var a = data.inst.get_container().find('li.category > a,li.folder > a');
        }else{
            var a = data.args[0].find('li.category > a,li.folder > a');
        }
        a.unbind('click');
        a.click(function(){
            jQuery('#' + trgt).jstree('toggle_node','#' + jQuery(this).parent().attr('id'));
        })
    },
    set_icon_active: function(data){
        if(data.args[0] == -1){
            var edit = data.inst.get_container().find('.edit');
        }else{
            var edit = data.args[0].find('.edit');
        }
        edit.each(function(){
            if(jQuery(this).css('display') == 'none'){
                jQuery(this).parent().parent().addClass('inactive');
            }
        })
    },
    set_more: function(data,trgt){
        /*
        var more = data.inst.get_container().find('.more');
        more.each(function(){
            jQuery(this).find('a').click(function(){
                var more_url = this.href;
                jQuery(this).addClass('jstree-loading');
                jQuery(this).find('span').html('Loading ...');
                var a = this;
                jQuery.ajax({
                    url: more_url,
                    dataType: 'html',
                    success: function(data){
                        
                    },
                    error: function(){
                        
                    }
                })
                return false;
            })
        })
        */
    },
    open_upload_dialog: function(a,blog_id){
        jQuery.fn.mtDialog.open(a.href);
        var open_id = a.parentNode.parentNode.parentNode.id;
        BlogTree.open_id = open_id;
        BlogTree.open_id_root = blog_id;
    },
    open_upload_dialog_root: function(a,blog_id){
        jQuery.fn.mtDialog.open(a.href);
        BlogTree.open_id = '';
        BlogTree.open_id_root = blog_id;
    },
    reload_noad: function(){
        var open_id = BlogTree.open_id;
        var open_id_root = BlogTree.open_id_root;
        if(open_id){
            var tree = jQuery.jstree._reference('#tree_' + open_id_root);
            tree.refresh('#' + open_id);
        }else{
            if(open_id_root){
                var tree = jQuery.jstree._reference('#tree_' + open_id_root);
                if(tree){
                    tree.refresh();
                }
            }
        }
    }
}

jQuery(function(){
    jQuery('.home .meta a').prepend('<ins class="jstree-icon">&nbsp;</ins>')
    jQuery('.home').hover(
        function(){
            jQuery(this).addClass('show_meta');
        },
        function(){
            jQuery(this).removeClass('show_meta');
        }
    )
    jQuery('.home > a:first-child').click(function(){
        var box = jQuery(this).parent().parent();
        box.toggleClass('hide_tree');
        if(box.hasClass('hide_tree')){
            jQuery(this).attr('title',BlogTree.trans['Show_Tree']);
        }else{
            jQuery(this).attr('title',BlogTree.trans['Hide_Tree']);
        }
    })
})
