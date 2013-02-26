jQuery(function(){
    jQuery('.toggle-link-wrapper').click(function(){
        jQuery(this).toggleClass('active');
        var left_pos = jQuery(this).offset().left;
        var top_pos = jQuery(this).offset().top + 22;
        var content_width = jQuery('body').width();
        var target_ele = jQuery('.display-options-detail');
        target_ele.toggle().css({
            'left': left_pos + 'px',
            'top': top_pos + 'px'
        });
        if(content_width < (left_pos + target_ele.outerWidth())){
            left_pos = jQuery(this).offset().left - (target_ele.outerWidth() - jQuery(this).outerWidth());
            jQuery('.display-options-detail').css({
                'left': left_pos + 'px'
            });
        }
        return false;
    });
    var close_options = function(){
        jQuery('.toggle-link-wrapper').removeClass('active');
        jQuery('.display-options-detail').hide();
    }
    jQuery('body').click(function(event){
        if(jQuery(event.target).parents('.display-options').length==0){
            close_options();
        }
    })
    jQuery('.toggle-button').click(function(event){
        close_options();
    })
})
