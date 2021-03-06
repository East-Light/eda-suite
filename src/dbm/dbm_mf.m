% Version 1.000
%
% Code provided by Ruslan Salakhutdinov
%
% Permission is granted for anyone to copy, use, modify, or distribute this
% program and accompanying programs and documents for any purpose, provided
% this copyright notice is retained and prominently displayed, along with
% a note saying that the original programs are available from our
% web page.
% The programs and documents are distributed without any warranty, express or
% implied.  As the programs were written for research purposes only, they have
% not been tested to the degree that would be advisable in any important
% application.  All use of these programs is entirely at the user's own risk.

%Note, Malte Probst, 2015: some small changes in the code (removed everything
% to do with classes, to make this entirely unsupervised)

%close all 
if restart ==1,
 epsilonw      = 0.001;   % Learning rate for weights 
 epsilonvb     = 0.002;   % Learning rate for biases of visible units 
 epsilonhb     = 0.002;   % Learning rate for biases of hidden units 
 weightcost  = 0.0002;   
 initialmomentum  = 0.3;
 finalmomentum    = 0.5;

 [numcases numdims numbatches]=size(batchdata);

 %numlab=10; 
 numdim=numdims;

  restart=0;
  epoch=1;
% Initializing symmetric weights and biases.
 
  vishid     = 0.001*randn(numdim, numhid);
  hidpen     = 0.001*randn(numhid,numpen); 

  %labpen = 0.001*randn(numlab,numpen); 

  hidbiases  = zeros(1,numhid);
  visbiases  = zeros(1,numdim);
  penbiases  = zeros(1,numpen);
  %labbiases  = zeros(1,numlab);

  poshidprobs = zeros(numcases,numhid);
  neghidprobs = zeros(numcases,numhid);
  posprods    = zeros(numdim,numhid);
  negprods    = zeros(numdim,numhid);

 
  vishidinc  = zeros(numdim,numhid);
  hidpeninc  = zeros(numhid,numpen);
  %labpeninc =  zeros(numlab,numpen); 
  

  hidbiasinc = zeros(1,numhid);
  visbiasinc = zeros(1,numdim);
  penbiasinc = zeros(1,numpen);
  %labbiasinc = zeros(1,numlab);

%%%% This code also adds sparcity penalty 
 sparsetarget = .2;
 sparsetarget2 = .1;
 sparsecost = .000; %Original by Salakhutdinov 0.001
 sparsedamping = .9;

   hidbiases  = 0*log(sparsetarget/(1-sparsetarget))*ones(1,numhid);
   hidmeans = sparsetarget*ones(1,numhid);
   penbiases  = 0*log(sparsetarget2/(1-sparsetarget2))*ones(1,numpen);
   penmeans = sparsetarget2*ones(1,numpen);

file=strcat("fullmnistpo",model.myrun);
load(file)

 hidpen = vishid;
 penbiases = hidbiases;
 visbiases_l2 = visbiases;
 %labpen = labhid;
 %clear labhid;

file=strcat("fullmnistvh",model.myrun);
load(file)
 hidrecbiases = hidbiases; 
 hidbiases = (hidbiases + visbiases_l2);
 epoch=1; 

 neghidprobs = (rand(numcases,numhid));
 %neglabstates = 1/10*(ones(numcases,numlab));
 data = round(rand(100,numdims));
 neghidprobs = 1./(1 + exp(-data*(2*vishid) - repmat(hidbiases,numcases,1)));

 epsilonw      = epsilonw/(1.000015^((epoch-1)*600));
 epsilonvb      = epsilonvb/(1.000015^((epoch-1)*600)); 
 epsilonhb      = epsilonhb/(1.000015^((epoch-1)*600)); 

 tot = 0; 
end

epocherrors=[];
epocherrors_smooth=[];
for epoch = epoch:maxepoch
  epocherrors=[epocherrors,0];
  %epocherrors_smooth=[epocherrors_smooth,0];
  [numcases numdims numbatches]=size(batchdata);

  fprintf(1,'epoch %d \t eps %f\r',epoch,epsilonw); 
  errsum=0;

  [numcases numdims numbatches]=size(batchdata);

  counter=0; 
  rr = randperm(numbatches);  
  batch=0; 
  for batch_rr = rr; %1:numbatches,
    batch=batch+1;  
    if model_params.loglevel >1
        fprintf(1,'epoch %d batch %d\r',epoch,batch); 
    end
    tot=tot+1; 
    epsilonw = max(epsilonw/1.0002,0.00010); % was max(epsilonw/1.000015,0.00010)
    epsilonvb = max(epsilonvb/1.0002,0.00010); %was max(epsilonvb/1.000015,0.00010); 
    epsilonhb = max(epsilonhb/1.0002,0.00010); %was  max(epsilonhb/1.000015,0.00010);


%%%%%%%%% START POSITIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    data = batchdata(:,:,batch);
    %targets = batchtargets(:,:,batch); 
    data = double(data > rand(numcases,numdim));  

%%%%% First fo MF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [poshidprobs, pospenprobs] = ...
         mf(data,"dummy",vishid,hidbiases,visbiases,hidpen,penbiases,"dummy",hidrecbiases);


    bias_hid= repmat(hidbiases,numcases,1);
    bias_pen = repmat(penbiases,numcases,1);
    bias_vis = repmat(visbiases,numcases,1);
    %bias_lab = repmat(labbiases,numcases,1);
  
    posprods    = data' * poshidprobs;
    posprodspen = poshidprobs'*pospenprobs;
    %posprodslabpen = targets'*pospenprobs;

    poshidact   = sum(poshidprobs);
    pospenact   = sum(pospenprobs);
    %poslabact   = sum(targets); 
    posvisact = sum(data);


%%%%%%%%% END OF POSITIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   negdata_CD1 = 1./(1 + exp(-poshidprobs*vishid' - bias_vis));
   %totin =  bias_lab + pospenprobs*labpen';
   %poslabprobs1 = exp(totin);
   %targetout = poslabprobs1./(sum(poslabprobs1,2)*ones(1,numlab));
   %[I J]=max(targetout,[],2);
   %[I1 J1]=max(targets,[],2);
   %counter=counter+length(find(J==J1));



%%%%% START NEGATIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if rand()>0.9 && 2<1
    %fprintf("tempchange!!\n");
    temperature=1.0;
    maxiter=100.0;
    for iter=1:maxiter 
        %iter
        if iter<maxiter/3.0
            %fprintf("heat")
            temperature=min(2,temperature+0.025);
        elseif iter>maxiter/2.0
            %fprintf("cool")
            temperature=max(1.0,temperature-0.1);
        end
        neghidstates = neghidprobs > rand(numcases,numhid);
      
        negpenprobs = 1./(1 + exp((-neghidstates*hidpen  - bias_pen)/temperature));
        negpenstates = negpenprobs > rand(numcases,numpen);

        negdataprobs = 1./(1 + exp((-neghidstates*vishid' - bias_vis)/temperature));
        negdata = negdataprobs > rand(numcases,numdim);

        %totin = negpenstates*labpen' + bias_lab;
        %neglabprobs = exp(totin);
        %neglabprobs = neglabprobs./(sum(neglabprobs,2)*ones(1,numlab)); 

        %xx = cumsum(neglabprobs,2);
        %xx1 = rand(numcases,1);
        %neglabstates = neglabstates*0;
        %for jj=1:numcases
        %  index = min(find(xx1(jj) <= xx(jj,:)));
        %  neglabstates(jj,index) = 1;
        %end
        %xxx = sum(sum(neglabstates)) ;

        totin = negdata*vishid + bias_hid + negpenstates*hidpen';
        neghidprobs = 1./(1 + exp(-totin/temperature));

    end 
  end
  
  
  for iter=1:5 
    neghidstates = neghidprobs > rand(numcases,numhid);
  
    negpenprobs = 1./(1 + exp(-neghidstates*hidpen  - bias_pen));
    negpenstates = negpenprobs > rand(numcases,numpen);

    negdataprobs = 1./(1 + exp(-neghidstates*vishid' - bias_vis));
    negdata = negdataprobs > rand(numcases,numdim);

    %totin = negpenstates*labpen' + bias_lab;
    %neglabprobs = exp(totin);
    %neglabprobs = neglabprobs./(sum(neglabprobs,2)*ones(1,numlab)); 

    %xx = cumsum(neglabprobs,2);
    %xx1 = rand(numcases,1);
    %neglabstates = neglabstates*0;
    %for jj=1:numcases
    %  index = min(find(xx1(jj) <= xx(jj,:)));
    %  neglabstates(jj,index) = 1;
    %end
    %xxx = sum(sum(neglabstates)) ;

    totin = negdata*vishid + bias_hid + negpenstates*hidpen';
    neghidprobs = 1./(1 + exp(-totin));

  end 
  negpenprobs = 1./(1 + exp(-neghidprobs*hidpen - bias_pen));

  negprods  = negdata'*neghidprobs;
  negprodspen = neghidprobs'*negpenprobs;
  neghidact = sum(neghidprobs);
  negpenact   = sum(negpenprobs);
  negvisact = sum(negdata); 
  %neglabact = sum(neglabstates); 
  %negprodslabpen = neglabstates'*negpenprobs;


%%%%%%%%% END OF NEGATIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  err= sum(sum( (data-negdata_CD1).^2 ));
  errsum = err + errsum;
  epocherrors(epoch)+=err;
  
   if epoch>50,
     momentum=finalmomentum;
   else
     momentum=initialmomentum;
   end;

%%%%%%%%% UPDATE WEIGHTS AND BIASES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

   visbiasinc = momentum*visbiasinc + (epsilonvb/numcases)*(posvisact-negvisact);
   %labbiasinc = momentum*labbiasinc + (epsilonvb/numcases)*(poslabact-neglabact);

   hidmeans = sparsedamping*hidmeans + (1-sparsedamping)*poshidact/numcases;
   sparsegrads = sparsecost*(repmat(hidmeans,numcases,1)-sparsetarget);

   penmeans = sparsedamping*penmeans + (1-sparsedamping)*pospenact/numcases;
   sparsegrads2 = sparsecost*(repmat(penmeans,numcases,1)-sparsetarget2);

   %labpeninc = momentum*labpeninc + ...
   %         epsilonw*( (posprodslabpen-negprodslabpen)/numcases - weightcost*labpen); 

   vishidinc = momentum*vishidinc + ...
               epsilonw*( (posprods-negprods)/numcases - weightcost*vishid - ...   
               data'*sparsegrads/numcases );
   hidbiasinc = momentum*hidbiasinc + epsilonhb/numcases*(poshidact-neghidact) ...
                -epsilonhb/numcases*sum(sparsegrads);

   hidpeninc = momentum*hidpeninc + ...
               epsilonw*( (posprodspen-negprodspen)/numcases - weightcost*hidpen - ...
               poshidprobs'*sparsegrads2/numcases - (pospenprobs'*sparsegrads)'/numcases );
   penbiasinc = momentum*penbiasinc + epsilonhb/numcases*(pospenact-negpenact) ...
                -epsilonhb/numcases*sum(sparsegrads2);

   vishid = vishid + vishidinc;
   hidpen = hidpen + hidpeninc;
   %labpen = labpen + labpeninc;
   visbiases = visbiases + visbiasinc;
   hidbiases = hidbiases + hidbiasinc;
   penbiases = penbiases + penbiasinc;
   %labbiases = labbiases + labbiasinc;
%%%%%%%%%%%%%%% END OF UPDATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  end
  %fprintf(1, 'epoch %4i reconstruction error %6.1f \n Number of misclassified training cases %d (out of 60000) \n', epoch, errsum,60000-counter); 
  epocherrors_smooth=[epocherrors_smooth,calcSmoothedError(epocherrors/(numcases*numbatches*numdims),model_params)];

  if model_params.loglevel>1 && mod(epoch,10)==0
      fprintf(1, 'epoch %4i reconstruction error %2.4f  \n', epoch, errsum/(numcases*numbatches*numdims)); 
      figure(999);
      plot(1:epoch,epocherrors./(numcases*numbatches*numdims));
      title("DBM recon err");
      %%%%%%%%
      fprintf(1, '\n', epoch, errsum/(numcases*numbatches*numdims)); 
      figure(998);
      
      plot(1:epoch,epocherrors_smooth);
      title("DBM recon err smooth");
      %replot();
  end
  
  stopTraining=checkTerminateTraining(epocherrors_smooth,model_params);
  
  
  if stopTraining
    break;
  end
  %if epoch>50
  % if epocherrors_smooth(epoch)>epocherrors_smooth(floor(epoch*0.9))
  % fprintf("Recon Err Grows! BREAK\n");
  % break;
  % end
  %end

end;
delete(strcat("./fullmnistpo",model.myrun))
delete(strcat("./fullmnistvh",model.myrun))

save ( strcat("fullmnist_dbm",model.myrun), "hidpen", "penbiases", "vishid" ,"hidbiases", "visbiases" )




