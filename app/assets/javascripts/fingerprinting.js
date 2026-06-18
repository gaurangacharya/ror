function captureFingerprints(components) {
  var values = components.map(function (component) { return component.value });
  var murmur = Fingerprint2.x64hash128(values.join(''), 31);
  $("a.with-fp").each(function(){this.href = this.href.replace(/(\?|&)ref=/, "$1ref="+murmur+"/");});
  $.ajax({url: "/logfp",type: "POST",data: JSON.stringify({hash_code: murmur, components: components}),contentType: 'application/json'});
}
if (window.requestIdleCallback) {
    requestIdleCallback(function () {Fingerprint2.get({excludes: {webgl: true, canvas: true, audio: true}}, captureFingerprints)});
} else {
    setTimeout(function () { Fingerprint2.get({excludes: {webgl: true, canvas: true, audio: true}}, captureFingerprints) }, 300);
}
