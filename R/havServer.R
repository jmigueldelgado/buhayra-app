

library(sf)
library(dplyr)
library(ggplot2)
library(lwgeom)

modified_molle = function(A,alpha_mod,K_mod,A0=5000) {
  V0=molle(A0)
  V = V0 + A0*((A-A0)/(alpha_mod*K_mod))^(1/alpha_mod^-1) + K_mod*((A-A0)/(alpha_mod*K_mod))^(alpha_mod/alpha_mod^-1)
  return(V)
  }

molle = function(A,alpha=2.7,K=1500) {
  V = K*(A/(alpha*K))^(alpha/(alpha-1))
  return(V)
  }


modified_alpha =  function(Pmax,Amax) {
  lambda=Amax/Pmax
  D=Pmax/pi
  return(2.08 + (1.46*10^1)*(lambda/Pmax) - (7.41*10^-2)*(lambda^2/Pmax) - (1.36*10^-8)*(Amax*D/lambda) + 4.07*10^-4*D)
}
modified_K = function(Pmax,Amax) {
  lambda=Amax/Pmax
  D=Pmax/pi
  return(2.55 * 10^3 + (6.45 * 10^1)*lambda - 5.38*10^1*(D/lambda))
}




watermasks=st_read('buhayra/auxdata/wm_utm_manuscript.gpkg')
 colnames(watermasks)
hav_params=watermasks %>%
  mutate(Amax=area,
    Pmax=unclass(st_perimeter(geom)),
    alpha_mod=modified_alpha(Pmax,Amax),
    K_mod = modified_K(Pmax,Amax),
    Vmax=modified_molle(Amax,alpha_mod,K_mod)) %>%
  st_set_geometry(NULL) %>%
  select(id_jrc,Amax,Pmax,Vmax,alpha_mod,K_mod)
head(hav_params)
