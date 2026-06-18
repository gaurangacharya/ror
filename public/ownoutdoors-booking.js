var OwnOutdoors = {
  username: null,

  base_url: null,

  init: function(base_url, username) {
    this.base_url = base_url;
    this.username = username;
  },

  book: function(url) {
    this.openIframe(url);
  },

  select: function() {
    this.openIframe(this.base_url+"/"+this.username+"/profile_listings");
  },

  close: function() {
    document.getElementById("ownoutdoors-content").remove();
    document.getElementById("ownoutdoors-overlay").remove();
  },

  openIframe: function(url) {
    var overlay = document.createElement("div");
    overlay.id = "ownoutdoors-overlay";
    document.body.appendChild(overlay);

    var content = document.createElement("div");
    content.id = "ownoutdoors-content";
    overlay.appendChild(content);

    var close = document.createElement("a");
    close.href = "#";
    close.onclick = this.close.bind(this);
    close.className = "ownoutdoors-close";
    close.innerHTML = "Close";
    content.appendChild(close);

    var iframeDiv = document.createElement("div");
    iframeDiv.className = 'ownoutdoors-iframe-loading';
    iframeDiv.id = "ownoutdoors-"+(new Date().getTime());
    content.appendChild(iframeDiv);

    this.embedIframe(iframeDiv, url);
  },

  display: function(container_id) {
    var div = document.getElementById(container_id);
    this.embedIframe(div, this.base_url+"/"+this.username+"/profile_listings", "&js_links=true");
  },

  embedIframe: function(iframeDiv, url, extra) {
    var iframe = document.createElement("iframe");
    iframe.name = "ownoutdoors-booking-iframe";
    iframe.id = "ownoutdoors-booking-iframe";
    iframe.width = "100%";
    iframe.className = "ownoutdoors-iframe";
    iframe.src = url+"?iframe=true"+(extra ? extra : "");
    iframe.onload = function() {
      iframeDiv.style.backgroundImage = "none";
    }
    iframeDiv.appendChild(iframe);

    iFrameResize({heightCalculationMethod: 'taggedElement', checkOrigin: false, minSize:100},  iframe);
  }
};
(function() {
  window.addEventListener("message", receiveMessage, false);

  function receiveMessage(event)
  {
    if (typeof event.data !== 'string')
      return;

    var m = event.data.match(/^OwnOutdoors:(.+)$/);
    if (!m)
      return;

    OwnOutdoors.book(m[1]);
  }
})();
