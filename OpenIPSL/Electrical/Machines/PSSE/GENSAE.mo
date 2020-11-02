within OpenIPSL.Electrical.Machines.PSSE;
model GENSAE "SALIENT POLE GENERATOR MODEL (EXPONENTIAL SATURATION)"
  extends Icons.VerifiedModel;
  // Import of Dependencies
  import OpenIPSL.NonElectrical.Functions.SE_exp;
  import Complex;
  import Modelica.ComplexMath.arg;
  import Modelica.ComplexMath.real;
  import Modelica.ComplexMath.imag;
  import Modelica.ComplexMath.'abs';
  import Modelica.ComplexMath.conj;
  import Modelica.ComplexMath.fromPolar;
  import Modelica.ComplexMath.j;
  //Extending machine base
  extends BaseClasses.baseMachine(
    EFD(start=efd0),
    XADIFD(start=efd0),
    PMECH(start=pm0),
    delta(start=delta0),
    id(start=id0),
    iq(start=iq0),
    ud(start=ud0),
    uq(start=uq0),
    Te(start=pm0));
  SI.PerUnit Epq(start=Epq0) "q-axis voltage behind transient reactance";
  SI.PerUnit PSIkd(start=PSIkd0) "d-axis rotor flux linkage";
  SI.PerUnit PSIppq(start=PSIppq0) "q-axis subtransient flux linkage";
  SI.PerUnit PSIppd(start=PSIppd0) "d-axis subtransient flux linkage";
  SI.PerUnit PSId(start=PSId0) "d-axis flux linkage";
  SI.PerUnit PSIq(start=PSIq0) "q-axis flux linkage";
  SI.PerUnit XadIfd(start=efd0) "Machine field current";
  SI.PerUnit PSIpp "Air-gap flux";
protected
  parameter Complex Zs=R_a + j*Xppd "Equivalent impedance";
  parameter Complex Is=real(It + VT/Zs) + j*imag(It + VT/Zs);
  parameter Complex PSIpp0=real(Zs*Is) + j*imag(Zs*Is);
  parameter Real ang_PSIpp0=arg(PSIpp0) "flux angle";
  parameter Real ang_It=arg(It) "current angle";
  parameter Real ang_PSIpp0andIt=ang_PSIpp0 - ang_It "angle difference";
  parameter SI.PerUnit abs_PSIpp0='abs'(PSIpp0)
    "magnitude of sub-transient flux linkage";
  parameter Complex VT=v_0*cos(angle_0rad) + j*v_0*sin(angle_0rad)
    "Complex terminal voltage";
  parameter Complex S=p0 + j*q0 "Complex power on machine base";
  parameter Complex It=real(S/VT) - j*imag(S/VT) "Terminal current";
  parameter Real a=abs_PSIpp0 + abs_PSIpp0*dsat*(Xq - Xl)/(Xd - Xl);
  parameter Real b=(It.re^2 + It.im^2)^0.5*(Xppd - Xq);
  //Initializion rotor angle position
  parameter Real delta0=atan(b*cos(ang_PSIpp0andIt)/(b*sin(ang_PSIpp0andIt) - a))
       + ang_PSIpp0 "initial rotor angle in radians";
  parameter Complex DQ_dq=cos(delta0) - j*sin(delta0) "Parks transformation";
  parameter Complex I_dq=real(It*DQ_dq) - j*imag(It*DQ_dq);
  //Initialization of current and voltage components in synchronous reference frame.
  parameter SI.PerUnit iq0=real(I_dq) "q-axis component of initial current";
  parameter SI.PerUnit id0=imag(I_dq) "d-axis component of initial current";
  parameter SI.PerUnit ud0=v_0*cos(angle_0rad - delta0 + C.pi/2)
    "d-axis component of initial voltage";
  parameter SI.PerUnit uq0=v_0*sin(angle_0rad - delta0 + C.pi/2)
    "q-axis component of initial voltage";
  parameter Complex PSIpp0_dq=real(PSIpp0*DQ_dq) + j*imag(PSIpp0*DQ_dq)
    "Flux linkage in rotor reference frame";
  parameter SI.PerUnit PSIppq0=-imag(PSIpp0_dq)
    "q-axis component of the sub-transient flux linkage";
  parameter SI.PerUnit PSIppd0=real(PSIpp0_dq)
    "d-axis component of the sub-transient flux linkage";
  parameter SI.PerUnit PSIkd0=(PSIppd0 - (Xpd - Xl)*K3d*id0)/(K3d + K4d)
    "d-axis initial rotor flux linkage";
  parameter SI.PerUnit PSId0=PSIppd0 - Xppd*id0;
  parameter SI.PerUnit PSIq0=(-PSIppq0) - Xppq*iq0;
  //Initialization mechanical power and field voltage.
  parameter SI.PerUnit Epq0=uq0 + Xpd*id0 + R_a*iq0;
  parameter Real dsat=SE_exp(
      abs_PSIpp0,
      S10,
      S12,
      1,
      1.2) "To include saturation of during initialization";
  parameter SI.PerUnit efd0=Epq0 + (Xd - Xpd)*id0 + PSIppd0*dsat
    "Initial field voltage magnitude";
  parameter SI.PerUnit pm0=p0 + R_a*iq0*iq0 + R_a*id0*id0
    "Initial mechanical power (pu machine base)";
  // Constants
  parameter Real K1d=(Xpd - Xppd)*(Xd - Xpd)/(Xpd - Xl)^2;
  parameter Real K2d=(Xpd - Xl)*(Xppd - Xl)/(Xpd - Xppd);
  parameter Real K3d=(Xppd - Xl)/(Xpd - Xl);
  parameter Real K4d=(Xpd - Xppd)/(Xpd - Xl);
initial equation
  der(Epq) = 0;
  der(PSIkd) = 0;
  der(PSIppq) = 0;
equation
  //Interfacing outputs with the internal variables
  XADIFD = XadIfd;
  PMECH0 = pm0;
  EFD0 = efd0;
  ISORCE = XadIfd;
  der(Epq) = 1/Tpd0*(EFD - XadIfd);
  der(PSIkd) = 1/Tppd0*(Epq - PSIkd - (Xpd - Xl)*id);
  der(PSIppq) = 1/Tppq0*((-PSIppq) + (Xq - Xppq)*iq - PSIppq*(Xq-Xl)/(Xd-Xl)*SE_exp(
   PSIpp,
   S10,
   S12,
   1,
   1.2));
  PSIppd = Epq*K3d + PSIkd*K4d;
  PSId = PSIppd - Xppd*id;
  PSIq = (-PSIppq) - Xppq*iq;
  PSIpp = sqrt(PSIppd*PSIppd + PSIppq*PSIppq);
  XadIfd = Epq + K1d*(Epq - PSIkd - (Xpd - Xl)*id) + (Xd - Xpd)*id + (SE_exp(
    PSIpp,
    S10,
    S12,
    1,
    1.2))*PSIppd;
  Te = PSId*iq - PSIq*id;
  ud = (-PSIq) - R_a*id;
  uq = PSId - R_a*iq;
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
            100}}), graphics={Text(
          extent={{-58,62},{52,-64}},
          lineColor={0,0,255},
          textString="GENSAE")}),
    Documentation(info="<html>
<table cellspacing=\"1\" cellpadding=\"1\" border=\"1\"><tr>
<td><p>Model Name</p></td>
<td><p>GENSAE</p></td>
</tr>
<tr>
<td><p>Reference</p></td>
<td><p>PSS/E Manual</p></td>
</tr>
<tr>
<td><p>Last update</p></td>
<td><p>September 2020</p></td>
</tr>
<tr>
<td><p>Author</p></td>
<td><p>Mengjia Zhang, SmarTS Lab, KTH Royal Institute of Technology</p></td>
</tr>
<tr>
<td><p>Contact</p></td>
<td><p><a href=\"mailto:vanfrl@rpi.edu\">vanfrl@rpi.edu</a></p></td>
</tr>
<tr>
<td><p>Model Verification</p></td>
<td><p>This model has been verified against PSS/E.</p></td>
</tr>
<tr>
<td><p>Description</p></td>
<td><p>Salient Pole Generator represented by equal mutual inductance rotor modeling. The model is the same as GENSAL model with the exception that an exponential function is used for saturation.</p></td>
</tr>
</table>
</html>"));
end GENSAE;
