for i in `cat list.txt`
do
   echo $i
   cd $i
   fslmaths cfmri.nii -Tmean Bold.nii.gz
   gunzip Bold.nii.gz
   cd ..
done
