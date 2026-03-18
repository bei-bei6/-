function GasOut=Mix(G1,G2,G3,G4,G5)
if nargin==2
%     GasOut.W=G1.W+G2.W;
%     p=[G1.W G2.W]/(G1.W+G2.W);
%     GasOut.Pt=sum([G1.Pt G2.Pt].*p);
%     GasOut.Tt=sum([G1.Tt G2.Tt].*p);
%     GasOut.FAR=sum([G1.FAR G2.FAR].*p);
%     GasOut.ht=sum([G1.ht G2.ht].*p);
    GasOut.W=G1.W+G2.W;
    p=[G1.W G2.W]/(G1.W+G2.W);
    GasOut.Pt=sum([G1.Pt G2.Pt].*p);
    GasOut.FAR=sum([G1.FAR G2.FAR].*p);
    GasOut.ht=sum([G1.ht G2.ht].*p);
    GasOut.Tt=hf_dp2t(GasOut.ht,GasOut.FAR,0,GasOut.Pt);
elseif nargin==3
    GasOut.W=G1.W+G2.W+G3.W;
    p=[G1.W G2.W G3.W]/(G1.W+G2.W+G3.W);
    GasOut.Pt=sum([G1.Pt G2.Pt  G3.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt].*p);
elseif nargin==4
    GasOut.W=G1.W+G2.W+G3.W+G4.W;
    p=[G1.W G2.W G3.W G4.W]/(G1.W+G2.W+G3.W+G4.W);
    GasOut.Pt=sum([G1.Pt G2.Pt  G3.Pt  G4.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt G4.Tt].*p);
elseif nargin==5
    GasOut.W=G1.W+G2.W+G3.W+G4.W+G5.W;
    p=[G1.W G2.W G3.W G4.W G5.W]/(G1.W+G2.W+G3.W+G4.W+G5.W);
    GasOut.Pt=sum([G1.Pt G2.Pt G3.Pt G4.Pt G5.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt G4.Tt G5.Tt].*p);
else
    error('最多支持5支路汇合')
end
end