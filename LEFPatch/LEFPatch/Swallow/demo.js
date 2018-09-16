defineClass('ViewController', {
    clickAction: function(sender) {
        self.setTitle(sender.currentTitle());
        self.clickAction2();
    },
    clickAction2: function() {
        self.setTitle('Lefex_add');
    }
})
