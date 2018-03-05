##getting DCM forecast=================================================
SELECT
  ITEM_ID,
  LOC_ID,
  FCST_WK_END_DT,
  FCST_GSLS_QTY
FROM
  `pr-supply-chain-thd.INVENTORY.DCM_ITEM_LOC_FCST`
WHERE
  _PARTITIONTIME >= TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL 28 DAY))
  AND _PARTITIONTIME < TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL 21 DAY))
  AND FCST_WK_END_DT >= DATE_SUB(CURRENT_DATE, INTERVAL 21 DAY)
  AND FCST_WK_END_DT < CURRENT_DATE

##=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_DCM_2018_01_28`

##transpose fcst to rows==========================================
SELECT
  ITEM_ID,
  LOC_ID,
  SUM(CASE
      WHEN FCST_WK_END_DT <= DATE_SUB(CURRENT_DATE, INTERVAL 14 DAY) THEN FCST_GSLS_QTY
      ELSE 0 END) AS WK1_FCST,
  SUM(CASE
      WHEN FCST_WK_END_DT <= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY) AND FCST_WK_END_DT > DATE_SUB(CURRENT_DATE, INTERVAL 14 DAY) THEN FCST_GSLS_QTY
      ELSE 0 END) AS WK2_FCST,
  SUM(CASE
      WHEN FCST_WK_END_DT <= CURRENT_DATE AND FCST_WK_END_DT > DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY) THEN FCST_GSLS_QTY
      ELSE 0 END) AS WK3_FCST
FROM
  `analytics-supplychain-thd.Derek.STOCK_OUT_DCM_2018_01_28`
GROUP BY
  1,
  2
#=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_FCST_feats_rows`


##getting features from CAR_PARM_ITEM_STR_INV=====================================

SELECT
  LOC_ID,
  ITEM_ID,
  CAL_DT,
  STR_INV_STR_VOL_LVL_CD,
  STR_INV_STRD_VOL_LVL_CD,
  STR_INV_STRC_VOL_LVL_CD,
  STR_INV_STRSC_VOL_LVL_CD,
  ITEM_VLCTY_CD,
  OH_QTY,
  OO_QTY,
  SELL_UOM_QTY,
  BUY_UOM_QTY,
  STR_INV_MIN_OH_QTY,
  SIMPL_OOS_IND AS TW_OOS_IND,
  NET_SLS_QTY,
  LOST_SLS_QTY,
  GRS_SLS_QTY,
  R8W_ASW_QTY,
  LEAD_TM_DAYS,
  LEAD_TM_QTY,
  REV_TM_QTY,
  REV_TM_DAYS_CNT,
  SFTY_STK_QTY,
  SVC_LVL_VAL,
  ASL_OSL_VAL,
  ADJ_ASW_QTY,
  CAR_PARM_CURR_RETL_AMT

FROM
  `pr-supply-chain-thd.INVENTORY.CAR_PARM_STR_ITEM_INV_WKLY`
WHERE
  _PARTITIONTIME >= TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL 28 DAY))
  AND _PARTITIONTIME < TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL 21 DAY))
  AND STR_INV_IPR_REPLE_IND = 1
  -- AND REV_TM_DAYS_CNT = 7

#=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_WK_2018_01_21_Feats


##getting labels ===============================================
SELECT
  LOC_ID,
  ITEM_ID,
  CAL_DT,
  SIMPL_OOS_IND
FROM
  `pr-supply-chain-thd.INVENTORY.CAR_PARM_STR_ITEM_INV_WKLY`
WHERE
  _PARTITIONTIME >= TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY))
  AND _PARTITIONTIME < TIMESTAMP(CURRENT_DATE())
  AND STR_INV_IPR_REPLE_IND = 1
  -- AND REV_TM_DAYS_CNT = 7

#=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_2018_02_11_labels

##taking subset of all stockouts and 5% of non-stockout ======================
with non_stockout as (
SELECT
  *
FROM
  `analytics-supplychain-thd.Derek.STOCK_OUT_2018_02_11_labels` 
WHERE
  SIMPL_OOS_IND = 0
  and rand() < 0.05
),

stockout as 
(SELECT
  *
FROM
  `analytics-supplychain-thd.Derek.STOCK_OUT_2018_02_11_labels`
WHERE
  SIMPL_OOS_IND = 1
)

select * from non_stockout 
union all
select * from stockout

#=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_subset_labels


 ##combine table to final master training
SELECT
  B.*,
  C.WK1_FCST,
  C.WK2_FCST,
  C.WK3_FCST,
  A.SIMPL_OOS_IND
FROM
  `analytics-supplychain-thd.Derek.STOCK_OUT_subset_labels` AS A
INNER JOIN
  `analytics-supplychain-thd.Derek.STOCK_OUT_WK_2018_01_21_Feats` AS B
ON
  A.ITEM_ID = B.ITEM_ID
  AND A.LOC_ID = B.LOC_ID
INNER JOIN
  `analytics-supplychain-thd.Derek.STOCK_OUT_FCST_feats_rows` AS C
ON
  A.ITEM_ID = C.ITEM_ID
  AND A.LOC_ID = C.LOC_ID
WHERE
  LEAD_TM_DAYS IS NOT NULL
  AND LEAD_TM_QTY IS NOT NULL
  AND REV_TM_QTY IS NOT NULL
  AND REV_TM_DAYS_CNT IS NOT NULL
  AND SFTY_STK_QTY IS NOT NULL
  AND SVC_LVL_VAL IS NOT NULL
  AND ASL_OSL_VAL IS NOT NULL
  AND ADJ_ASW_QTY IS NOT NULL
  AND CAR_PARM_CURR_RETL_AMT IS NOT NULL

#=========save result to `analytics-supplychain-thd.Derek.STOCK_OUT_master_training