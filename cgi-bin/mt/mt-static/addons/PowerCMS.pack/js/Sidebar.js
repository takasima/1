var get_browser_height = function(){
    if (document.documentElement) {
        var height = document.documentElement.clientHeight;
    } else {
        var height = Math.min(
            screen.availHeight,
            jQuery(document.body).innerHeight()
        );
    }
    return height;
}

jQuery(function() {
    sidebar.height = get_browser_height();
    sidebar.ele_top = jQuery('#main').offset().top;
    sidebar.pos_header = jQuery('#header').outerHeight();

    // sidebar positioning
    sidebar.set_sidebar_position(sidebar.height);
    
    jQuery(window).resize(function(){
        sidebar.height = get_browser_height();
        sidebar.set_sidebar_position(sidebar.height);
    });
    jQuery(window).scroll(function(){
        sidebar.set_sidebar_position(sidebar.height);
    });
    
    sidebar.tab_focus();
    // sidebar.menu_width = jQuery('#menu_wrapper').outerWidth();

    // ----------------------------------------
    // Change tab
    // ----------------------------------------
    jQuery('#menu_tabs a').mouseup(function(){
        sidebar.menu_width = jQuery.cookie("menu_width")
            ? jQuery.cookie("menu_width")
            : jQuery.cookie("menu_width", 153);
        sidebar.menu_width = Number(sidebar.menu_width) + 21;
        sidebar.tab_click(this);
        sidebar.tab_focus();
    return false;
    }).click(function(){
        return false;
    });
});

var sidebar = {
    set_sidebar_position: function(v_height){
        var scroll_val = jQuery(window).scrollTop();
        if(scroll_val >= sidebar.pos_header){
            jQuery('#menu_wrapper').css({
                'position': 'fixed',
                'top': '15px'
            });
            jQuery('#manu_stage').css({
                'height': (v_height - 15) +  'px'
            });
        }else{
            jQuery('#menu_wrapper').css({
                'position': 'absolute',
                'top': 'auto'
            });
            jQuery('#manu_stage').css({
                'height': (v_height - sidebar.ele_top) + scroll_val +  'px'
            });
        }
    },
    current_tab: 'menu',
    tab_click: function(a){
        var current_tab = jQuery(a).attr('href').split('#')[1];
        if(sidebar.close){
            sidebar.current_tab = current_tab;
        }
        if(sidebar.current_tab == current_tab){
            sidebar.toggle_menu(a);
        }else{
        }
        sidebar.current_tab = current_tab;
        sidebar.change_tab_item(current_tab);
    },
    toggle_menu: function(a){
        var menu_def_width = 153;
        set_sidebar_size(menu_def_width,true);
        if(sidebar.close){
            var move = sidebar.menu_width;
            var f_move = move - 21;
        }else{
            var move = '21';
            var f_move = '0';
        }
        jQuery('#content').animate(
            {
                marginLeft: move + 'px'
            },{
                duration: 'fast',
                complete: function(){
                    if(sidebar.close){
                        sidebar.close = false;
                    }else{
                        sidebar.close = true;
                    }
                    sidebar.bake_cookie();
                }
            }
        );
        jQuery('#footer,.debug-panel').animate(
            {
                left: f_move + 'px'
            },{
                duration: 'fast',
                easing: 'easeInQuad'
            }
        );
    },
    tab_focus: function(){
        jQuery('#menu_tabs li a').removeClass('current');
        
        var trg = '.trigger_' + sidebar.current_tab;
        jQuery(trg + ' a').addClass('current');
    },
    check_tab: function(){
        var tab_close = Cookie.fetch( 'tab_close' );
        if( tab_close && tab_close.value && tab_close.value != "" ){
            document.write('<style type="text/css">.has-menu-nav #content{margin-left:21px}#footer,.debug-panel{left:0px}</style>');
            sidebar.close = true;
        }
    },
    change_tab_item: function(current_tab){
        jQuery('.tab_item').hide();
        jQuery('#tab_' + current_tab).show();
    },
    bake_cookie: function(){
        var close = '';
        if(sidebar.close){
            close = 1;
        }
        var d = new Date();
        d.setYear( d.getYear() + 1902 ); /* two years */
        Cookie.bake( 'tab_close', close, undefined, undefined, d );
    }
};

sidebar.check_tab();

var set_sidebar_size = function(menu_def_width,toggle){
    jQuery.cookie("menu_width")
        ? jQuery("#menu").css("width", jQuery.cookie("menu_width") + "px")
        : jQuery.cookie("menu_width", menu_def_width);
    
    if(!toggle){
        jQuery.cookie("content_margin")
            ? jQuery("#content").css("margin-left", jQuery.cookie("content_margin") + "px")
            : jQuery.cookie("content_margin", 175);
    }
    
    jQuery.cookie("menu_margin")
        ? jQuery("#menu_wrapper").css("margin-left", jQuery.cookie("menu_margin") + "px")
        : jQuery.cookie("menu_margin", -190);

    jQuery.cookie("tabs_position")
        ? jQuery("#menu_tabs").css("left", jQuery.cookie("tabs_position") + "px")
        : jQuery.cookie("tabs_position", 153);

    jQuery.cookie("footer_position")
        ? jQuery("#footer, .debug-panel").css("left", jQuery.cookie("footer_position") + "px")
        : jQuery.cookie("footer_position", 154);
}

jQuery(function() {
    var menu_def_width = 153;
    var content = jQuery("#content");
    var menu = jQuery("#menu_wrapper");
    var tabs = jQuery("#menu_tabs");
    var footer = jQuery("#footer, .debug-panel");

    if(!sidebar.close){
        set_sidebar_size(menu_def_width);
    }

    jQuery("#menu").resizable({
        handles: 'e',
        maxWidth: 400,
        minWidth: menu_def_width,
        start: function(event, ui) {
            this.content_start_margin = 175;
            this.menu_start_margin = -190;
            this.tabs_start_position = 153;
            this.footer_start_position = 154;
        },
        resize: function(event, ui) {
            content.css("margin-left", (ui.size.width - menu_def_width) + Number(this.content_start_margin) + "px");
            menu.css("margin-left", - (ui.size.width - menu_def_width) + Number(this.menu_start_margin) + "px");
            tabs.css("left", (ui.size.width - menu_def_width) + Number(this.tabs_start_position) + "px");
            footer.css("left", (ui.size.width - menu_def_width) + Number(this.footer_start_position) + "px");
        },
        stop: function(event, ui) {
            jQuery.cookie("menu_width", ui.size.width);
            jQuery.cookie("content_margin", jQuery("#content").css("margin-left").replace(/px/, ""));
            jQuery.cookie("menu_margin", jQuery("#menu_wrapper").css("margin-left").replace(/px/, ""));
            jQuery.cookie("tabs_position", jQuery("#menu_tabs").css("left").replace(/px/, ""));
            jQuery.cookie("footer_position", jQuery("#footer, .debug-panel").css("left").replace(/px/, ""));
        }
    });
});
