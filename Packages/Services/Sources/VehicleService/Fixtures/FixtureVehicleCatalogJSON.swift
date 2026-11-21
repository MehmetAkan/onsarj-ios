// Geçici veri (K-23, K-26): `FixtureVehicleCatalog`'un JSON'u; backend bağlanınca silinir.
//
// DEĞERLER ÖRNEKTİR: teknik doğruluk iddiası yoktur. Biçim `Docs/Backend/vehicle-catalog.md` ile aynıdır:
// üç uç noktanın kayıtları (`brands`, `models`, `variants`) tek dizgede.
#if DEBUG
/// Katalog tipinin gövdesini kısa tutmak için dosya düzeyinde sabit.
let fixtureVehicleCatalogJSON = """
    {
      "brands": [
        {"id": "brand_togg", "name": "Togg", "logoUrl": null, "modelCount": 1},
        {"id": "brand_byd", "name": "BYD", "logoUrl": null, "modelCount": 3},
        {"id": "brand_tesla", "name": "Tesla", "logoUrl": null, "modelCount": 2},
        {"id": "brand_renault", "name": "Renault", "logoUrl": null, "modelCount": 2},
        {"id": "brand_hyundai", "name": "Hyundai", "logoUrl": null, "modelCount": 2},
        {"id": "brand_kia", "name": "Kia", "logoUrl": null, "modelCount": 2},
        {"id": "brand_volkswagen", "name": "Volkswagen", "logoUrl": null, "modelCount": 2},
        {"id": "brand_bmw", "name": "BMW", "logoUrl": null, "modelCount": 2},
        {"id": "brand_mercedes", "name": "Mercedes-Benz", "logoUrl": null, "modelCount": 2},
        {"id": "brand_mg", "name": "MG", "logoUrl": null, "modelCount": 2}
      ],
      "models": [
        {"id": "model_togg_t10x", "brandId": "brand_togg", "name": "T10X", "bodyType": "suv"},
        {"id": "model_byd_dolphin", "brandId": "brand_byd", "name": "Dolphin", "bodyType": "hatchback"},
        {"id": "model_byd_atto3", "brandId": "brand_byd", "name": "Atto 3", "bodyType": "suv"},
        {"id": "model_byd_seal", "brandId": "brand_byd", "name": "Seal", "bodyType": "sedan"},
        {"id": "model_tesla_model3", "brandId": "brand_tesla", "name": "Model 3", "bodyType": "sedan"},
        {"id": "model_tesla_modely", "brandId": "brand_tesla", "name": "Model Y", "bodyType": "suv"},
        {"id": "model_renault_megane", "brandId": "brand_renault", "name": "Megane E-Tech", "bodyType": "hatchback"},
        {"id": "model_renault_zoe", "brandId": "brand_renault", "name": "Zoe", "bodyType": "hatchback"},
        {"id": "model_hyundai_ioniq5", "brandId": "brand_hyundai", "name": "IONIQ 5", "bodyType": "suv"},
        {"id": "model_hyundai_kona", "brandId": "brand_hyundai", "name": "Kona Electric", "bodyType": "suv"},
        {"id": "model_kia_ev6", "brandId": "brand_kia", "name": "EV6", "bodyType": "suv"},
        {"id": "model_kia_niro", "brandId": "brand_kia", "name": "Niro EV", "bodyType": "suv"},
        {"id": "model_volkswagen_id3", "brandId": "brand_volkswagen", "name": "ID.3", "bodyType": "hatchback"},
        {"id": "model_volkswagen_id4", "brandId": "brand_volkswagen", "name": "ID.4", "bodyType": "suv"},
        {"id": "model_bmw_i4", "brandId": "brand_bmw", "name": "i4", "bodyType": "sedan"},
        {"id": "model_bmw_ix3", "brandId": "brand_bmw", "name": "iX3", "bodyType": "suv"},
        {"id": "model_mercedes_eqa", "brandId": "brand_mercedes", "name": "EQA", "bodyType": "suv"},
        {"id": "model_mercedes_eqe", "brandId": "brand_mercedes", "name": "EQE", "bodyType": "sedan"},
        {"id": "model_mg_mg4", "brandId": "brand_mg", "name": "MG4", "bodyType": "hatchback"},
        {"id": "model_mg_zsev", "brandId": "brand_mg", "name": "ZS EV", "bodyType": "suv"}
      ],
      "variants": [
        {
          "id": "variant_togg_t10x_v1_rwd",
          "modelId": "model_togg_t10x",
          "name": "V1 RWD Standart Menzil",
          "modelYear": 2024,
          "batteryCapacityKwh": 52.4,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 150,
          "referenceConsumptionKwhPer100Km": 16.9,
          "imageUrl": null
        },
        {
          "id": "variant_togg_t10x_v2_rwd",
          "modelId": "model_togg_t10x",
          "name": "V2 RWD Uzun Menzil",
          "modelYear": 2024,
          "batteryCapacityKwh": 88.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 22,
          "maxDcPowerKw": 180,
          "referenceConsumptionKwhPer100Km": 17.6,
          "imageUrl": null
        },
        {
          "id": "variant_byd_dolphin_standard",
          "modelId": "model_byd_dolphin",
          "name": "Standart",
          "modelYear": 2023,
          "batteryCapacityKwh": 60.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 88,
          "referenceConsumptionKwhPer100Km": 17.8,
          "imageUrl": null
        },
        {
          "id": "variant_byd_atto3_comfort",
          "modelId": "model_byd_atto3",
          "name": "Comfort",
          "modelYear": 2023,
          "batteryCapacityKwh": 60.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 88,
          "referenceConsumptionKwhPer100Km": 18.0,
          "imageUrl": null
        },
        {
          "id": "variant_byd_seal_excellence_awd",
          "modelId": "model_byd_seal",
          "name": "Excellence AWD",
          "modelYear": 2024,
          "batteryCapacityKwh": 82.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 150,
          "referenceConsumptionKwhPer100Km": 18.5,
          "imageUrl": null
        },
        {
          "id": "variant_tesla_model3_sr_rwd",
          "modelId": "model_tesla_model3",
          "name": "Standard Range RWD",
          "modelYear": 2024,
          "batteryCapacityKwh": 57.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 170,
          "referenceConsumptionKwhPer100Km": 14.0,
          "imageUrl": null
        },
        {
          "id": "variant_tesla_model3_lr_awd",
          "modelId": "model_tesla_model3",
          "name": "Long Range AWD",
          "modelYear": 2024,
          "batteryCapacityKwh": 78.1,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 250,
          "referenceConsumptionKwhPer100Km": 15.0,
          "imageUrl": null
        },
        {
          "id": "variant_tesla_modely_rwd",
          "modelId": "model_tesla_modely",
          "name": "RWD",
          "modelYear": 2024,
          "batteryCapacityKwh": 57.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 170,
          "referenceConsumptionKwhPer100Km": 15.5,
          "imageUrl": null
        },
        {
          "id": "variant_renault_megane_ev60_techno",
          "modelId": "model_renault_megane",
          "name": "EV60 Techno",
          "modelYear": 2023,
          "batteryCapacityKwh": 60.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 22,
          "maxDcPowerKw": 130,
          "referenceConsumptionKwhPer100Km": 16.1,
          "imageUrl": null
        },
        {
          "id": "variant_renault_zoe_r135",
          "modelId": "model_renault_zoe",
          "name": "R135",
          "modelYear": 2022,
          "batteryCapacityKwh": 52.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 22,
          "maxDcPowerKw": 46,
          "referenceConsumptionKwhPer100Km": 17.2,
          "imageUrl": null
        },
        {
          "id": "variant_hyundai_ioniq5_rwd77",
          "modelId": "model_hyundai_ioniq5",
          "name": "77 kWh RWD",
          "modelYear": 2023,
          "batteryCapacityKwh": 77.4,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 233,
          "referenceConsumptionKwhPer100Km": 17.0,
          "imageUrl": null
        },
        {
          "id": "variant_hyundai_kona_kwh64",
          "modelId": "model_hyundai_kona",
          "name": "64 kWh",
          "modelYear": 2023,
          "batteryCapacityKwh": 64.8,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 102,
          "referenceConsumptionKwhPer100Km": 15.4,
          "imageUrl": null
        },
        {
          "id": "variant_kia_ev6_gtline_rwd",
          "modelId": "model_kia_ev6",
          "name": "GT-Line RWD",
          "modelYear": 2023,
          "batteryCapacityKwh": 77.4,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 233,
          "referenceConsumptionKwhPer100Km": 16.5,
          "imageUrl": null
        },
        {
          "id": "variant_kia_niro_kwh64",
          "modelId": "model_kia_niro",
          "name": "64 kWh",
          "modelYear": 2023,
          "batteryCapacityKwh": 64.8,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 80,
          "referenceConsumptionKwhPer100Km": 16.2,
          "imageUrl": null
        },
        {
          "id": "variant_volkswagen_id3_pro",
          "modelId": "model_volkswagen_id3",
          "name": "Pro",
          "modelYear": 2023,
          "batteryCapacityKwh": 58.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 120,
          "referenceConsumptionKwhPer100Km": 15.8,
          "imageUrl": null
        },
        {
          "id": "variant_volkswagen_id4_pro",
          "modelId": "model_volkswagen_id4",
          "name": "Pro",
          "modelYear": 2023,
          "batteryCapacityKwh": 77.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 135,
          "referenceConsumptionKwhPer100Km": 17.4,
          "imageUrl": null
        },
        {
          "id": "variant_bmw_i4_edrive40",
          "modelId": "model_bmw_i4",
          "name": "eDrive40",
          "modelYear": 2023,
          "batteryCapacityKwh": 80.7,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 205,
          "referenceConsumptionKwhPer100Km": 16.1,
          "imageUrl": null
        },
        {
          "id": "variant_bmw_ix3_msport",
          "modelId": "model_bmw_ix3",
          "name": "M Sport",
          "modelYear": 2023,
          "batteryCapacityKwh": 74.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 150,
          "referenceConsumptionKwhPer100Km": 18.5,
          "imageUrl": null
        },
        {
          "id": "variant_mercedes_eqa_250plus",
          "modelId": "model_mercedes_eqa",
          "name": "250+",
          "modelYear": 2023,
          "batteryCapacityKwh": 70.5,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 100,
          "referenceConsumptionKwhPer100Km": 16.8,
          "imageUrl": null
        },
        {
          "id": "variant_mercedes_eqe_350plus",
          "modelId": "model_mercedes_eqe",
          "name": "350+",
          "modelYear": 2023,
          "batteryCapacityKwh": 90.6,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 170,
          "referenceConsumptionKwhPer100Km": 17.0,
          "imageUrl": null
        },
        {
          "id": "variant_mg_mg4_standard",
          "modelId": "model_mg_mg4",
          "name": "Standard",
          "modelYear": 2023,
          "batteryCapacityKwh": 51.0,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 6.6,
          "maxDcPowerKw": 117,
          "referenceConsumptionKwhPer100Km": 16.0,
          "imageUrl": null
        },
        {
          "id": "variant_mg_zsev_long_range",
          "modelId": "model_mg_zsev",
          "name": "Long Range",
          "modelYear": 2023,
          "batteryCapacityKwh": 72.6,
          "connectors": ["type2", "ccs2"],
          "maxAcPowerKw": 11,
          "maxDcPowerKw": 92,
          "referenceConsumptionKwhPer100Km": 17.8,
          "imageUrl": null
        }
      ]
    }
    """
#endif
