var Validator = function (params) {
    this.errors = [];
    this.validations = [];
};

(function($) {
    
    Validator.prototype.append = function (fn) {
        this.validations.push(fn);
    }
    
    Validator.prototype.run = function (elem, params) {
        var self = this;
        self.errors = [];
        var form = $(elem);
        $.each(this.validations, function() {
            this.call( self, form, params );
        });
        return (self.errors.length == 0);
    }

})(jQuery);
