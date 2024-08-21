# ChinaPlants.jl

[![CI](https://github.com/Mikumikunisiteageru/ChinaPlants.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/Mikumikunisiteageru/ChinaPlants.jl/actions/workflows/CI.yml)

**UNDER DEVELOPMENT**

This Julia package integrates online research sources about Plant species in China, including information of taxonomy, phylogeny, and conservation biology.

The data are not embedded in the source of this package. After installation, all materials will be downloaded automatically and processed once the related information is requested. 

Currently data sources include the following three.

### Taxonomy

[*Checklist of plant species in China* (*2024 Edition*) / 中国植物物种名录（2024版）](https://www.plantplus.cn/doi/10.12282/plantdata.1476)

Cite this part as:
```bibtex
@database{Checklist2024,
	author = {{Institute of Botany, Chinese Academy of Sciences}},
	title = {Checklist of plant species in {China} (2024 edition)},
	publisher = {Plant Data Center of Chinese Academy of Sciences},
	year = {2024},
	doi = {10.12282/plantdata.1476},
	url = {https://www.plantplus.cn/doi/10.12282/plantdata.1476},
}
```

### Phylogeny

[*Dataset of the Chinese Angiosperm Tree of Life* / 中国被子植物生命之树数据集](https://www.plantplus.cn/doi/10.5061/dryad.6m905qg2w)

Cite this part as:
```bibtex
@article{Lu2022,
	author = {Limin Lu and Lina Zhao and Haihua Hu and Bing Liu and Yuchang Yang and Yichen You and Danxiao Peng and Russell L. Barrett and Zhiduan Chen},
	title = {A comprehensive evaluation of flowering plant diversity and conservation priority for national park planning in {China}},
	journal = {Fundamental Research},
	year = {2022},
	doi = {10.1016/j.fmre.2022.08.008},
	url = {https://www.sciencedirect.com/science/article/pii/S2667325822003491},
}
@database{Tree2022,
	author = {Limin Lu and Lina Zhao and Haihua Hu and Bing Liu and Yuchang Yang and Yichen You and Danxiao Peng and Russell L. Barrett and Zhiduan Chen},
	title = {Dataset of the {Chinese} angiosperm tree of life},
	publisher = {Plant Data Center of Chinese Academy of Sciences},
	year = {2022},
	doi = {10.5061/dryad.6m905qg2w},
	url = {https://www.plantplus.cn/doi/10.5061/dryad.6m905qg2w},
}
```

### Conservation biology

[*Red List of China's Biodiversity: Part of Higher Plants* (*2020*) (unofficial translation) / 中国生物多样性红色名录—高等植物卷（2020）](https://www.mee.gov.cn/xxgk2018/xxgk/xxgk01/202305/t20230522_1030745.html)

Cite this part as:
```bibtex
@database{RedList2020,
	author = {{Ministry of Ecology and Environment, The People's Republic of China} and {Chinese Academy of Sciences}},
	title = {{Red List} of {China}'s biodiversity: part of higher plants (2020)},
	howpublished = {https://www.mee.gov.cn/xxgk2018/xxgk/xxgk01/202305/t20230522_1030745.html},
	year = {2023},
}
```
