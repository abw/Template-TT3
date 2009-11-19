var TT3 = { 
};

TT3.tree = function(config) {
    var root = $(config.element);

    root.find('div.head').click(
        function() {
            $(this).closest('div.element').toggleClass('open');
        }
    );
}; 

TT3.tabset = function(config) {
    var root = $(config.element);
    root.find('ul.tabs li a').click(
        function() {
            var that = $(this);
            that.closest('li').make_warm();
            $(that.attr('href')).make_warm();
            return false;
        }
    );
}; 

jQuery.fn.extend({
    tt3_tree: function() {
        this.each( 
            function() {
                TT3.tree({ element: this });
            }
        );
    },
    tt3_tabset: function() {
        this.each( 
            function() {
                TT3.tabset({ element: this });
            }
        );
    },
    make_warm: function() {
        this.addClass('warm').siblings('.warm').removeClass('warm');
        return this;
    },
});
