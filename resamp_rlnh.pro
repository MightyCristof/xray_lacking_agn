PRO resamp_rlnh, ll_std, $
                 ll_mad, $
                 nh_std, $
                 nh_mad


common _det_wac
common _xconv
common _agnlum
common _quality
common _combined


ifin = where(iifinal_det,nf)
lxraw = dblarr(nsrc)

for i = 0,nfield-1 do begin
    re = execute('ivalid = where(lxraw eq 0. and IIFINAL_DET'+xfield[i]+')')
    re = execute('lxraw[ivalid] = lx'+xfield[i]+'[ivalid]')
endfor
loglxraw = alog10(lxraw[ifin])
loglxirf = loglxir[ifin]

llsamp = dblarr(1000,nf)
nhsamp = dblarr(1000,nf)
ll_std = dblarr(nf)
ll_mad = dblarr(nf)
nh_std = dblarr(nf)
nh_mad = dblarr(nf)

for i = 0,nf-1 do begin
    llsamp[*,i] = loglxraw[i]-(loglxirf[i]+randomn(seed,1000)*0.3)
    ll_std[i] = stddev(llsamp[*,i])
    ll_mad[i] = medabsdev(llsamp[*,i])
    nhsamp[*,i] = rl2nh(llsamp[*,i],model='borus')    
    nh_std[i] = stddev(nhsamp[*,i])
    nh_mad[i] = medabsdev(nhsamp[*,i])
endfor


END



