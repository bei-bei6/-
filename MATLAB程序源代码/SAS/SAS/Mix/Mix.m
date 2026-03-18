function GasOut=Mix(G1,G2,G3,G4,G5)
if nargin==2
    GasOut.W=G1.W+G2.W;
    p=[G1.W G2.W]/(G1.W+G2.W);
    GasOut.Pt=sum([G1.Pt G2.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt].*p);
    GasOut.Swirl=sum([G1.Swirl G2.Swirl].*p);
    if isfield(G1,'Ps') && isfield(G2,'Ps')
        GasOut.Ps=sum([G1.Ps G2.Ps].*p);
    end
elseif nargin==3
    GasOut.W=G1.W+G2.W+G3.W;
    p=[G1.W G2.W G3.W]/(G1.W+G2.W+G3.W);
    GasOut.Pt=sum([G1.Pt G2.Pt  G3.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt].*p);
    GasOut.Swirl=sum([G1.Swirl G2.Swirl G3.Swirl].*p);
    if isfield(G1,'Ps') && isfield(G2,'Ps') && isfield(G3,'Ps')
        GasOut.Ps=sum([G1.Ps G2.Ps G3.Ps].*p);
    end
elseif nargin==4
    GasOut.W=G1.W+G2.W+G3.W+G4.W;
    p=[G1.W G2.W G3.W G4.W]/(G1.W+G2.W+G3.W+G4.W);
    GasOut.Pt=sum([G1.Pt G2.Pt  G3.Pt  G4.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt G4.Tt].*p);
    GasOut.Swirl=sum([G1.Swirl G2.Swirl G3.Swirl G4.Swirl].*p);
elseif nargin==5
    GasOut.W=G1.W+G2.W+G3.W+G4.W+G5.W;
    p=[G1.W G2.W G3.W G4.W G5.W]/(G1.W+G2.W+G3.W+G4.W+G5.W);
    GasOut.Pt=sum([G1.Pt G2.Pt G3.Pt G4.Pt G5.Pt].*p);
    GasOut.Tt=sum([G1.Tt G2.Tt G3.Tt G4.Tt G5.Tt].*p);
    GasOut.Swirl=sum([G1.Swirl G2.Swirl G3.Swirl G4.Swirl G5.Swirl].*p);
else
    error('最多支持5支路汇合')
end
end