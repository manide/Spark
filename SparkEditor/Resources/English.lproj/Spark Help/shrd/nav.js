function set_links() {    for(var i = 0; i < document.links.length; i++) {        document.links[i].onmousedown = highlight;    }        var last_highlighted;    var last_display;    var last_color;        var topic_title;    var page_title;}function highlight() {    if (last_highlighted) {        last_highlighted.style.display = last_display;        last_highlighted.style.color = last_color;    }    last_highlighted = this;    last_display = this.style.display;    last_color = this.style.color;    topic_title = this.text;    this.style.display = "block";    this.style.color = "purple";}