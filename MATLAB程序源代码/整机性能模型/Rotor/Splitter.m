function [BypassOut,MFPOut]=Splitter(MFPIn,BPR)
BypassOut.W=BPR*MFPIn.W;
BypassOut.ht=MFPIn.ht;
BypassOut.Tt=MFPIn.Tt;
BypassOut.Pt=MFPIn.Pt;
BypassOut.FAR=MFPIn.FAR;

MFPOut.W=(1-BPR)*MFPIn.W;
MFPOut.ht=MFPIn.ht;
MFPOut.Tt=MFPIn.Tt;
MFPOut.Pt=MFPIn.Pt;
MFPOut.FAR=MFPIn.FAR;
end


