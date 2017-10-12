## /* -*- javascript -*-

<%! clip_shader=True %>

<%inherit file="base.mako"/>

<%block name="title">Find the linear combination</%block>

<%block name="inline_style">
  .overlay-popup h2 {
     color: green;
  }
  .overlay-text p:last-child {
     font-size: 80%;
  }
  .dg.main .cr.number.has-slider > div > .property-name {
      width: 10%;
  }
  .dg.main .cr.number.has-slider > div > .c {
      width: 90%;
  }
  .dg.main .cr.number.has-slider > div > .c .slider {
      width: 85%;
  }
  .dg.main .cr.number.has-slider > div > .c input {
      width: 10%;
  }
</%block>

## */

var paramsQS = Demo.prototype.decodeQS();
var range = [[-10,10],[-10,10],[-10,10]];
if(paramsQS.range) {
    range = parseFloat(paramsQS.range);
    range = [[-range, range], [-range, range], [-range, range]];
}
var camera = [-1.5, 1.5, -3];
if(paramsQS.camera) {
    camera = paramsQS.camera.split(",").map(parseFloat);
}

new Demo({
    camera: {
        proxy:     true,
        position: camera,
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    },
    grid: false,
    popup: true,
    caption: '&nbsp;',
    viewRange: range,

}, function() {
    var self = this;
    var zero_threshold = 0.00001;

    var vector1, vector2, vector3, target;
    var vectors = [];
    var labels = [];
    var color1 = [1, .3, 1, 1];
    var color2 = [0, 1, 0, 1];
    var color3 = [1, 1, 0, 1];
    var colors = [];

    var numVecs = 0;
    if(paramsQS.w)
        target = paramsQS.w.split(",").map(parseFloat);
    if(paramsQS.v3) {
        numVecs = 3;
        vector1 = paramsQS.v1.split(",").map(parseFloat);
        vector2 = paramsQS.v2.split(",").map(parseFloat);
        vector3 = paramsQS.v3.split(",").map(parseFloat);
        vectors = [vector1, vector2, vector3];
        labels = ['v1', 'v2', 'v3'];
        colors = [color1, color2, color3];
    }
    else if(paramsQS.v2) {
        numVecs = 2;
        vector1 = paramsQS.v1.split(",").map(parseFloat);
        vector2 = paramsQS.v2.split(",").map(parseFloat);
        vector3 = [0, 0, 0];
        vectors = [vector1, vector2];
        labels = ['v1', 'v2'];
        colors = [color1, color2];
    }
    else if(paramsQS.v1) {
        numVecs = 1;
        vector1 = paramsQS.v1.split(",").map(parseFloat);
        vector2 = [0, 0, 0];
        vector3 = [0, 0, 0];
        vectors = [vector1];
        labels = ['v1'];
        colors = [color1];
    } else {
        return;
    }

    // gui
    var Params = function() {
        this.x = 1.0;
        this.y = 1.0;
        this.z = 1.0;
        this.Axes = false;
    };
    var params = new Params();
    var gui = new dat.GUI({width: 300});
    var doAxes = gui.add(params, 'Axes');

    var checkDone = function() {
        if(!target) return;
        var lincombo = [
            vector1[0]*params.x + vector2[0]*params.y + vector3[0]*params.z,
            vector1[1]*params.x + vector2[1]*params.y + vector3[1]*params.z,
            vector1[2]*params.x + vector2[2]*params.y + vector3[2]*params.z
        ];
        if(target[0] == lincombo[0] &&
           target[1] == lincombo[1] &&
           target[2] == lincombo[2]) {
            var caption = "<h2>Success!</h2>";
            var a = params.x;
            if(a == 1) a = '';
            else if(a == -1) a = '-';
            var eqn = a + colorize(tColor1, self.render_vec(vector1));
            if(numVecs >= 2) {
                var b = Math.abs(params.y);
                if(b == 1) b = '';
                var add = params.y >= 0 ? "+" : "-";
                eqn += add + b + colorize(tColor2, self.render_vec(vector2));
            }
            if(numVecs >= 3) {
                var c = Math.abs(params.z);
                if(c == 1) c = '';
                var add = params.z >= 0 ? "+" : "-";
                eqn += add + c + colorize(tColor3, self.render_vec(vector3));
            }
            eqn += "= " + self.render_vec(target);
            self.show_popup(caption + "<p>" + katex.renderToString(eqn) + "</p>");
        }
        else
            self.hide_popup();
    };

    gui.add(params, 'x', -10, 10).step(0.1).onChange(checkDone);
    if(numVecs >= 2)
        gui.add(params, 'y', -10, 10).step(0.1).onChange(checkDone);
    if(numVecs >= 3)
        gui.add(params, 'z', -10, 10).step(0.1).onChange(checkDone);

    doAxes.onFinishChange(function(val) {
        mathbox.select(".axes").set("visible", val);
    });
    mathbox.select(".axes").set("visible", this.Axes);

    var ortho1 = new THREE.Vector3(vector1[0],vector1[1],vector1[2]);
    var ortho2 = new THREE.Vector3(vector2[0],vector2[1],vector2[2]);
    var ortho = [ortho1, ortho2];
    var tColor1 = new THREE.Color(color1[0], color1[1], color1[2]);
    var tColor2 = new THREE.Color(color2[0], color2[1], color2[2]);
    var tColor3 = new THREE.Color(color3[0], color3[1], color3[2]);
    var tColors = [tColor1, tColor2, tColor3];

    var tVec1 = new THREE.Vector3(vector1[0], vector1[1], vector1[2]);
    var tVec2 = new THREE.Vector3(vector2[0], vector2[1], vector2[2]);
    var tVec3 = new THREE.Vector3(vector3[0], vector3[1], vector3[2]);

    // Compute the span
    var spanDim;
    var cross = new THREE.Vector3();
    cross.crossVectors(tVec1, tVec2);
    if(Math.abs(cross.dot(tVec3)) > zero_threshold)
        spanDim = 3;
    else {
        if(cross.dot(cross) > zero_threshold) {
            spanDim = 2;
            this.orthogonalize(ortho1.copy(tVec1), ortho2.copy(tVec2));
        }
        else {
            cross.crossVectors(tVec1, tVec3);
            if(cross.dot(cross) > zero_threshold) {
                spanDim = 2;
                this.orthogonalize(ortho1.copy(tVec1), ortho3.copy(tVec2));
            }
            else {
                cross.crossVectors(tVec2, tVec3);
                if(cross.dot(cross) > zero_threshold) {
                    spanDim = 2;
                    this.orthogonalize(ortho1.copy(tVec2), ortho3.copy(tVec3));
                }
                else if(tVec1.dot(tVec1) > zero_threshold) {
                    spanDim = 1;
                    ortho1.copy(tVec1).normalize()
                }
                else if(tVec2.dot(tVec2) > zero_threshold) {
                    spanDim = 1;
                    ortho1.copy(tVec2).normalize()
                }
                else if(tVec3.dot(tVec3) > zero_threshold) {
                    spanDim = 1;
                    ortho1.copy(tVec3).normalize()
                }
                else
                    spanDim = 0;
            }
        }
    }

    this.labeledVectors(vectors, colors, labels, {
    });
    mathbox.select("#vectors-drawn").set('zIndex', 2);
    mathbox.select("#vector-labels").set('zIndex', 3);

    if(target) {
        this.labeledVectors([target], [[1,1,1,1]], ['w'], {
            prefix: 'target-',
        });
        mathbox.select("#target-vectors-drawn").set('zIndex', 2);
        mathbox.select("#target-vector-labels").set('zIndex', 3);
    }

    // linear combination
    if(numVecs == 3) {
        this.view
            .array({
                id:       "lincombo",
                channels: 3,
                width:    2,
                items:    12,
                expr: function(emit, i) {
                    var vec1 = [vector1[0]*params.x,
                                vector1[1]*params.x,
                                vector1[2]*params.x];
                    var vec2 = [vector2[0]*params.y,
                                vector2[1]*params.y,
                                vector2[2]*params.y];
                    var vec3 = [vector3[0]*params.z,
                                vector3[1]*params.z,
                                vector3[2]*params.z];
                    var vec12 = [vec1[0]+vec2[0], vec1[1]+vec2[1], vec1[2]+vec2[2]];
                    var vec13 = [vec1[0]+vec3[0], vec1[1]+vec3[1], vec1[2]+vec3[2]];
                    var vec23 = [vec2[0]+vec3[0], vec2[1]+vec3[1], vec2[2]+vec3[2]];
                    var vec123 = [vec1[0] + vec2[0] + vec3[0],
                                  vec1[1] + vec2[1] + vec3[1],
                                  vec1[2] + vec2[2] + vec3[2]]
                    if(i == 0) {
                        // starting points of lines
                        emit(0, 0, 0);
                        emit(0, 0, 0);
                        emit(0, 0, 0);
                        emit.apply(null, vec1);
                        emit.apply(null, vec1);
                        emit.apply(null, vec2);
                        emit.apply(null, vec2);
                        emit.apply(null, vec3);
                        emit.apply(null, vec3);
                        emit.apply(null, vec12);
                        emit.apply(null, vec13);
                        emit.apply(null, vec23);
                    }
                    else {
                        // ending points of lines
                        emit.apply(null, vec1);
                        emit.apply(null, vec2);
                        emit.apply(null, vec3);
                        emit.apply(null, vec12);
                        emit.apply(null, vec13);
                        emit.apply(null, vec12);
                        emit.apply(null, vec23);
                        emit.apply(null, vec13);
                        emit.apply(null, vec23);
                        emit.apply(null, vec123);
                        emit.apply(null, vec123);
                        emit.apply(null, vec123);
                    }
                }
            })
            .array({
                id:       "lincombo-colors",
                channels: 4,
                width:    2,
                items:    12,
                data:     [color1, color2, color3, color2, color3, color1,
                           color3, color1, color2, color3, color2, color1,
                           color1, color2, color3, color2, color3, color1,
                           color3, color1, color2, color3, color2, color1],
            })
        ;
    } else if(numVecs == 2) {
        this.view
            .array({
                id:       "lincombo",
                channels: 3,
                width:    2,
                items:    4,
                expr: function(emit, i) {
                    var vec1 = [vector1[0]*params.x,
                                vector1[1]*params.x,
                                vector1[2]*params.x];
                    var vec2 = [vector2[0]*params.y,
                                vector2[1]*params.y,
                                vector2[2]*params.y];
                    var vec12 = [vec1[0] + vec2[0],
                                 vec1[1] + vec2[1],
                                 vec1[2] + vec2[2]];
                    if(i == 0) {
                        emit(0, 0, 0);
                        emit(0, 0, 0);
                        emit.apply(null, vec1);
                        emit.apply(null, vec2);
                    } else {
                        emit.apply(null, vec1);
                        emit.apply(null, vec2);
                        emit.apply(null, vec12);
                        emit.apply(null, vec12);
                    }
                }
            })
            .array({
                id:       "lincombo-colors",
                channels: 4,
                width:    2,
                items:    4,
                data:     [color1, color2, color2, color1,
                           color1, color2, color2, color1],
            })
        ;
    } else if(numVecs == 1) {
        this.view
            .array({
                id:       "lincombo",
                channels: 3,
                width:    2,
                items:    1,
                expr: function(emit, i) {
                    if(i == 0)
                        emit(0, 0, 0);
                    else
                        emit(vector1[0]*params.x,
                             vector1[1]*params.x,
                             vector1[2]*params.x);
                }
            })
            .array({
                id:       "lincombo-colors",
                channels: 4,
                width:    1,
                items:    1,
                data:     [color1],
            })
        ;
    }

    this.view
        .line({
            classes: ["linear-combo"],
            points:  "#lincombo",
            color:   "white",
            colors:  "#lincombo-colors",
            opacity: 0.75,
            width:   3,
            zIndex:  1,
        })
        .array({
            channels: 3,
            width:    1,
            expr: function(emit) {
                emit(vector1[0]*params.x + vector2[0]*params.y + vector3[0]*params.z,
                     vector1[1]*params.x + vector2[1]*params.y + vector3[1]*params.z,
                     vector1[2]*params.x + vector2[2]*params.y + vector3[2]*params.z);
            },
        })
        .point({
            classes: ["linear-combo"],
            color:  "rgb(0,255,255)",
            zIndex: 2,
            size:   15,
        })
        .text({
            live:  true,
            width: 1,
            expr: function(emit) {
                var ret = params.x.toFixed(2) + "v1";
                if(numVecs >= 2) {
                    var b = Math.abs(params.y);
                    var add = params.y >= 0 ? "+" : "-";
                    ret += add + b.toFixed(2) + "v2";
                }
                if(numVecs >= 3) {
                    var c = Math.abs(params.z);
                    var add = params.z >= 0 ? "+" : "-";
                    ret += add + c.toFixed(2) + "v3";
                }
                emit(ret);
            },
        })
        .label({
            classes: ["linear-combo"],
            outline: 0,
            color:  "rgb(0,255,255)",
            offset:  [0, 25],
            size:    15,
            zIndex:  3,
        })
    ;

    // Spanning surface stuff
    var surfaceColor = new THREE.Color(0.5, 0, 0);
    var surfaceOpacity = 0.5;

    var clipped = this.clipCube({
        drawCube: true,
        wireframeColor: new THREE.Color(.75, .75, .75),
        material: new THREE.MeshBasicMaterial({
            color:       surfaceColor,
            opacity:     0.5,
            transparent: true,
            visible:     true,
            depthWrite:  false,
            depthTest:   true,
        }),
    });

    if(spanDim == 2) {
        clipped
            .matrix({
                channels: 3,
                live:     false,
                width:    2,
                height:   2,
                expr: function (emit, i, j) {
                    if(i == 0) i = -1;
                    if(j == 0) j = -1;
                    i *= 30; j *= 30;
                    emit(ortho1.x * i + ortho2.x * j,
                         ortho1.y * i + ortho2.y * j,
                         ortho1.z * i + ortho2.z * j);
                },
            })
            .surface({
                color:   surfaceColor,
                opacity: surfaceOpacity,
                stroke:  "solid",
                width:   5,
            })
        ;
    } else if(spanDim == 1) {
        clipped
            .array({
                channels: 3,
                live:     false,
                width:    2,
                expr: function (emit, i) {
                    if(i == 0) i = -1;
                    i *= 30;
                    emit(ortho1.x * i, ortho1.y * i, ortho1.z * i);
                },
            })
            .line({
                color:   surfaceColor,
                opacity: 1.0,
                stroke:  "solid",
                width:   5,
            })
        ;
    }

    var colorize = function(col, text) {
        return "\\color{#" + col.getHexString() + "}{" + text + "}";
    };

    var eqn = "x" + colorize(tColor1, this.render_vec(vector1));
    if(numVecs >= 2)
        eqn += "+ y" + colorize(tColor2, this.render_vec(vector2));
    if(numVecs >= 3)
        eqn += "+ z" + colorize(tColor3, this.render_vec(vector3));

    var mat = "\\begin{bmatrix}";
    var rows = [];
    for(var i = 0; i < 3; ++i) {
        var row = [];
        for(var j = 0; j < numVecs; ++j)
            row.push(colorize(tColors[j], vectors[j][i]));
        rows.push(row.join("&"));
    }
    mat += rows.join("\\\\") +  "\\end{bmatrix}";

    var abc = ['x', 'y', 'z'].slice(0,numVecs);
    eqn = mat + "\\begin{bmatrix}" + abc.join("\\\\") + "\\end{bmatrix} = " + eqn;
    if(target)
        eqn += "= " + this.render_vec(target) + "= w";

    var caption = "";
    if(target)
        caption = "<p>Solve this equation by moving the sliders:</p>";
    caption += "<p>" + katex.renderToString(eqn) + "</p>";

    this.label.innerHTML = caption;
});
