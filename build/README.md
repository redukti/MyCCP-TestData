## Steps

```
dylan sr30y.lua > sr30y.txt
dylan eonia.lua > eonia.txt
dylan extract_3m_eonia.lua > eonia3m.txt
dylan extract_3m_euribor.lua > euribor3m.txt
dylan extract_6m_eonia.lua > eonia6m.txt
dylan extract_6m_euribor.lua > euribor6m.txt
dylan build_eur_curves.lua eonia > ../data/eonia.txt
dylan build_eur_curves.lua euribor > ../data/euribor.txt
dylan extract_fxrates.lua > ../data\eurfxrates.txt
```