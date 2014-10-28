function [null_inds,var1,var2,var3,var4]=get_rid_of_nulls(invar1,invar2,invar3,invar4);
  
   null_inds=find(invar1==-1); 
   var1=invar1;
   var1(null_inds)=[];
   var2=invar2;
   var2(null_inds)=[];
   var3=invar3;
   var3(null_inds)=[];
   var4=invar4;
   var4(null_inds)=[];
   
