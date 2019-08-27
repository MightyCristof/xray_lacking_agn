;; takes in OBS files, this is before fitting
PRO subset_xray_field_obs, in_files

;; output SAV file string
sav_str = ((strsplit(in_files,'/',/extract,/regex)).toArray())[*,-1]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; CHANDRA MASTER
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chandra Master Path
mast_path_cha = '/Users/ccarroll/Research/surveys/Chandra/*master*.fits'
;; 3XMM-DR8 Serendip Catalog Per-Observation Source Table
cat_path_cha = '/Users/ccarroll/Research/surveys/Chandra/observation-source-2.fits'
;; Chandra Master arch_chaive
arch_cha = mrdfits(mast_path_cha,1)
;; Master Catalog is updated more frequently than CSC2! 
;; avoid spurious non-detections!
cat_cha = mrdfits(cat_path_cha,1)
;; use only OBSID that are in cat_chaalots
mast_id_cha = arch_cha.obsid
cat_id_cha = cat_cha[where(cat_cha.instrument eq 'ACIS',/null)].obsid
cat_id_cha = cat_id_cha[uniq(cat_id_cha,sort(cat_id_cha))]
match,mast_id_cha,cat_id_cha,imast_cha,icat_cha
iiarch_cha = bytarr(n_elements(arch_cha))
iiarch_cha[imast_cha] = 1
arch_cha = arch_cha[where(iiarch_cha,/null)]
;; use only arch_chaived sources
arch_cha = arch_cha[where(arch_cha.status eq 'ARCHIVED' or arch_cha.status eq 'OBSERVED',/null)]
arch_cha = arch_cha[where(arch_cha.detector eq 'ACIS-I',/null)]
;; ACIS-I FOV is 16'x16'
;; https://heasarc.gsfc.nasa.gov/docs/chandra/chandra.html
fov_cha = 16.*60./2.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; XMM-NEWTON MASTER
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; XMM Master Path
mast_path_xmm = '/Users/ccarroll/Research/surveys/XMM/*master*.fits'
;; 3XMM-DR8 Serendip cat_xmmalog
cat_path_xmm = '/Users/ccarroll/Research/surveys/XMM/3XMM_DR8cat_xmm_v1.0.fits'
;; XMM Master arch_xmmive
arch_xmm = mrdfits(mast_path_xmm,1)
;; Master cat_xmmalog is updated more frequently than 3XMM-DR8! 
;; avoid spurious non-detections!
cat_xmm = mrdfits(cat_xmm_path_xmm,1)
;; use only OBSID that are in cat_xmmalots
mast_id_xmm = arch_xmm.obsid
cat_id_xmm = cat_xmm.obs_id
cat_id_xmm = cat_id_xmm[uniq(cat_id_xmm,sort(cat_id_xmm))]
match,mast_id_xmm,cat_id_xmm,imast_xmm,icat_xmm
iiarch_xmm = bytarr(n_elements(arch_xmm))
iiarch_xmm[imast_xmm] = 1
arch_xmm = arch_xmm[where(iiarch_xmm,/null)]
;; use only arch_xmmived sources (possibly use )
arch_xmm = arch_xmm[where(arch_xmm.status eq 'ARCHIVED' or arch_xmm.status eq 'OBSERVED',/null)]  ;; observed sources
arch_xmm = arch_xmm[where(arch_xmm.pn_time gt 0.,/null)]                                      ;; ensure PN observation
arch_xmm = arch_xmm[where(arch_xmm.duration gt 0.,/null)]                                     ;; sanity check
iimode = strmatch(arch_xmm.pn_mode,'*FLG*',/fold) or $                          ;; ensure Large-Window or Full-Frame mode
         strmatch(arch_xmm.pn_mode,'*FF*',/fold) or $
         strmatch(arch_xmm.pn_mode,'*EFF*',/fold)
arch_xmm = arch_xmm[where(iimode,/null)]
;; XMM PN MOS FOV is ~27.5'x27.5'; use FOV inscribed circle--being conservative
;; https://heasarc.gsfc.nasa.gov/docs/xmm/xmm.html
fov_xmm = 27.5*60./2.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; NuSTAR MASTER
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Combined NuSTAR Fields Path
mast_path_nst = '/Users/ccarroll/Research_nst/surveys/NuSTAR/*master*.fits'
;; NuSTAR cat_nstalogs
cat_path_nst = '/Users/ccarroll/Research_nst/surveys/NuSTAR/combined_nustar_fields.fits'
;; Read in the NuSTAR observation information (HEASARC);
arch_nst = mrdfits(mast_path_nst,1)
;; Master cat_nstalog is updated more frequently than 3XMM-DR8! 
;; avoid spurious non-detections!
cat_nst = mrdfits(cat_path_nst,1)
;; NuSTAR FOV is 13'x13'
;; https://heasarc.gsfc.nasa.gov/docs/nustar/nustar.html
fov_nst = 13.*60./2.
spherematch,arch_nst.ra,arch_nst.dec,cat_nst.ra,cat_nst.dec,fov_nst/3600.,imast_nst,icat_nst,sep,maxmatch=0
iiarch_nst = bytarr(n_elements(arch_nst))
iiarch_nst[imast_nst] = 1
arch_nst = arch_nst[where(iiarch_nst,/null)]
;; for NuSTAR, select just the science subset
arch_nst = arch_nst[where(arch_nst.observation_mode eq 'SCIENCE',/null)]
;; pull data from arch_nst
ra_nst = arch_nst.ra
dec_nst = arch_nst.dec
rot_angle = arch_nst.roll_angle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; LOOP OVER EACH FILE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for i = 0,n_elements(in_files)-1 do begin
    print, 'WORKING FIELD: '+in_files[i]
    
    restore,in_files[i]
    nsrc = n_elements(obs)

    iiinf_cha = bytarr(nsrc)
    iiinf_xmm = bytarr(nsrc)
    iiinf_nst = bytarr(nsrc)

    ;; CHANDRA 
    spherematch,ra,dec,arch_cha.ra,arch_cha.dec,fov_cha/3600.,isamp_cha,ifield,sep_cntr,maxmatch=0
    iiinf_cha[isamp_cha] = 1

    ;; XMM
    spherematch,ra,dec,arch_xmm.ra,arch_xmm.dec,fov_xmm/3600.,isamp_xmm,ifield,sep_cntr,maxmatch=0
    iiinf_xmm[isamp_xmm] = 1

    ;; NUSTAR
    spherematch,ra,dec,ra_nst,dec_nst,fov_nst/3600.,is,ix,sepnu,maxmatch=0
    isu = is[uniq(is,sort(is))]
    ixu = ix[uniq(ix,sort(ix))]
    ;; for each sample source
    for n=0L,n_elements(ra[isu])-1 do begin 
       ;; for each x-ray observation
       for m=0L,n_elements(ra_nst[ixu])-1 do begin 
          GCIRC, 2, ra_nst[ixu[m]],dec_nst[ixu[m]],ra[isu[n]],dec[isu[n]],dist_test
          if (dist_test le 2000.) then begin
             nustar_fov,ra_nst[ixu[m]],dec_nst[ixu[m]],rot_angle[ixu[m]],box_enc_x,box_enc_y   
             dummy=IsPointInPolygon(box_enc_x,box_enc_y,ra[isu[n]],dec[isu[n]])
             if (dummy eq -1) then iiinf_nst[isu[n]] = 1
          endif
       endfor
    endfor

    ;; COMBINE ALL FIELDS NOW
    iiinf = iiinf_cha or iiinf_xmm or iiinf_nst
    iinf = where(iiinf,ct)
    if (ct eq 0) then continue
    obs = obs[iinf]
    save,obs,band,/compress,file=sav_str[i]    
endfor


END








