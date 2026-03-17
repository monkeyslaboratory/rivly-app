// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Registers a platform view factory that creates an iframe with inline Three.js
/// hero scene matching the Rivly landing page animation.
void registerThreeJsBackground(String viewType, bool isDark) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final bgColor = isDark ? '#050505' : '#FAFAFA';
    final colors = isDark
        ? "['#4338CA','#6366F1','#818CF8','#FF6B2C','#FF4500']"
        : "['#6366F1','#818CF8','#A5B4FC','#FF8F5C','#FFB088']";
    final particleColor = isDark ? '#FF6B2C' : '#E55A1B';

    final iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.pointerEvents = 'none'
      ..srcdoc = '''
<!DOCTYPE html>
<html><head>
<style>*{margin:0;padding:0;overflow:hidden}body{background:$bgColor}canvas{display:block}</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"><\/script>
</head><body>
<script>
(function(){
const W=window.innerWidth,H=window.innerHeight;
const scene=new THREE.Scene();
const camera=new THREE.PerspectiveCamera(45,W/H,0.1,100);
camera.position.z=5;
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});
renderer.setSize(W,H);renderer.setPixelRatio(Math.min(window.devicePixelRatio,1.5));
document.body.appendChild(renderer.domElement);

const colors=$colors.map(c=>new THREE.Color(c));

const orbVS=\`
uniform float uTime,uNoiseScale,uNoiseStrength;
varying vec3 vPos,vNorm;varying float vDisp;
vec4 pm(vec4 x){return mod(((x*34.0)+1.0)*x,289.0);}
vec4 ti(vec4 r){return 1.79284291400159-0.85373472095314*r;}
float sn(vec3 v){const vec2 C=vec2(1.0/6.0,1.0/3.0);const vec4 D=vec4(0,0.5,1,2);
vec3 i=floor(v+dot(v,C.yyy));vec3 x0=v-i+dot(i,C.xxx);
vec3 g=step(x0.yzx,x0.xyz);vec3 l=1.0-g;vec3 i1=min(g,l.zxy);vec3 i2=max(g,l.zxy);
vec3 x1=x0-i1+C.xxx;vec3 x2=x0-i2+C.yyy;vec3 x3=x0-D.yyy;i=mod(i,289.0);
vec4 p=pm(pm(pm(i.z+vec4(0,i1.z,i2.z,1))+i.y+vec4(0,i1.y,i2.y,1))+i.x+vec4(0,i1.x,i2.x,1));
float n_=1.0/7.0;vec3 ns=n_*D.wyz-D.xzx;vec4 j=p-49.0*floor(p*ns.z*ns.z);
vec4 x_=floor(j*ns.z);vec4 y_=floor(j-7.0*x_);vec4 x=x_*ns.x+ns.yyyy;vec4 y=y_*ns.x+ns.yyyy;
vec4 h=1.0-abs(x)-abs(y);vec4 b0=vec4(x.xy,y.xy);vec4 b1=vec4(x.zw,y.zw);
vec4 s0=floor(b0)*2.0+1.0;vec4 s1=floor(b1)*2.0+1.0;vec4 sh=-step(h,vec4(0));
vec4 a0=b0.xzyw+s0.xzyw*sh.xxyy;vec4 a1=b1.xzyw+s1.xzyw*sh.zzww;
vec3 p0=vec3(a0.xy,h.x);vec3 p1=vec3(a0.zw,h.y);vec3 p2=vec3(a1.xy,h.z);vec3 p3=vec3(a1.zw,h.w);
vec4 norm=ti(vec4(dot(p0,p0),dot(p1,p1),dot(p2,p2),dot(p3,p3)));
p0*=norm.x;p1*=norm.y;p2*=norm.z;p3*=norm.w;
vec4 m=max(0.6-vec4(dot(x0,x0),dot(x1,x1),dot(x2,x2),dot(x3,x3)),0.0);m=m*m;
return 42.0*dot(m*m,vec4(dot(p0,x0),dot(p1,x1),dot(p2,x2),dot(p3,x3)));}
void main(){float n=sn(position*uNoiseScale+uTime*0.15);float d=n*uNoiseStrength;vDisp=d;
vec3 np=position+normal*d;vPos=np;vNorm=normal;gl_Position=projectionMatrix*modelViewMatrix*vec4(np,1.0);}
\`;

const orbFS=\`
uniform float uTime;uniform vec3 uColor1,uColor2,uColor3,uColor4,uColor5;
varying vec3 vPos,vNorm;varying float vDisp;
void main(){float t=uTime*0.07;float ph=fract(t);int idx=int(mod(t,5.0));vec3 c;
if(idx==0)c=mix(uColor1,uColor2,ph);else if(idx==1)c=mix(uColor2,uColor3,ph);
else if(idx==2)c=mix(uColor3,uColor4,ph);else if(idx==3)c=mix(uColor4,uColor5,ph);
else c=mix(uColor5,uColor1,ph);
vec3 vd=normalize(cameraPosition-vPos);float f=pow(1.0-max(dot(vd,vNorm),0.0),3.0);
c+=f*0.4;c=mix(c,uColor1,vDisp*0.3);gl_FragColor=vec4(c,0.85+f*0.15);}
\`;

const orbMat=new THREE.ShaderMaterial({
  transparent:true,depthWrite:false,
  uniforms:{uTime:{value:0},uNoiseScale:{value:1.2},uNoiseStrength:{value:0.35},
    uColor1:{value:colors[0]},uColor2:{value:colors[1]},uColor3:{value:colors[2]},
    uColor4:{value:colors[3]},uColor5:{value:colors[4]}},
  vertexShader:orbVS,fragmentShader:orbFS
});
const orb=new THREE.Mesh(new THREE.IcosahedronGeometry(1,64),orbMat);
orb.scale.setScalar(2.5);orb.position.y=-0.5;

const pCount=80;const pGeo=new THREE.BufferGeometry();
const pPos=new Float32Array(pCount*3);
for(let i=0;i<pCount;i++){pPos[i*3]=(Math.random()-0.5)*10;pPos[i*3+1]=(Math.random()-0.5)*10;pPos[i*3+2]=(Math.random()-0.5)*6;}
pGeo.setAttribute('position',new THREE.BufferAttribute(pPos,3));
const pts=new THREE.Points(pGeo,new THREE.PointsMaterial({size:0.03,color:'$particleColor',transparent:true,opacity:0.4,sizeAttenuation:true}));

const group=new THREE.Group();
group.add(orb);group.add(pts);
scene.add(group);
scene.add(new THREE.AmbientLight(0xffffff,0.5));
const pl=new THREE.PointLight(new THREE.Color('#FF6B2C'),0.8);pl.position.set(5,5,5);scene.add(pl);

let mx=0,my=0;
document.addEventListener('mousemove',e=>{mx=(e.clientX/W-0.5)*2;my=(e.clientY/H-0.5)*2;});

function animate(){
  requestAnimationFrame(animate);
  orbMat.uniforms.uTime.value+=0.005;
  orb.rotation.y+=0.0001;orb.rotation.x+=0.00004;
  const arr=pGeo.attributes.position.array;
  for(let i=0;i<pCount;i++){arr[i*3+1]+=0.005*(0.03+Math.random()*0.02);if(arr[i*3+1]>5)arr[i*3+1]=-5;}
  pGeo.attributes.position.needsUpdate=true;
  group.rotation.x+=(my*0.08-group.rotation.x)*0.05;
  group.rotation.y+=(mx*0.08-group.rotation.y)*0.05;
  renderer.render(scene,camera);
}
animate();
window.addEventListener('resize',()=>{
  const w=window.innerWidth,h=window.innerHeight;
  camera.aspect=w/h;camera.updateProjectionMatrix();renderer.setSize(w,h);
});
})();
<\/script>
<div style="position:absolute;inset:0;pointer-events:none;backdrop-filter:blur(24px);-webkit-backdrop-filter:blur(24px)"></div>
<div style="position:absolute;inset:0;pointer-events:none;background:radial-gradient(ellipse at center,transparent 30%,$bgColor 80%)"></div>
</body></html>
''';

    return iframe;
  });
}
