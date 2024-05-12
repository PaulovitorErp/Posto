#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} LJR130GR
Ponto de entrada permite efetuar qualquer atualização na base após a gravação dos itens da nota fiscal (arquivo SD2), 
pois é chamado logo após a geração desse arquivo..

@author Totvs
@since 28/08/2019
@version 1.0
@return lRet

@type function
/*/
/***********************/
User Function TRETP019()
/***********************/

	Local aArea		:= GetArea()
	Local aAreaMDL  := MDL->(GetArea())
	Local _lAjNfCup := SuperGetMv("MV_XAJNFCU",.F.,.F.) //Ajusta o VALOR BRUTO da Nota Sobre Cupom (Default .F.)
	Local nVldTot := 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	DbSelectArea("MDL")
	MDL->(DbSetOrder(1)) // MDL_FILIAL+MDL_NFCUP+MDL_SERIE+MDL_CUPOM+MDL_SERCUP

	If MDL->(DbSeek(xFilial("MDL")+SF2->F2_DOC+SF2->F2_SERIE))

		If _lAjNfCup
			AjSD2ValBrut() //Ajusta o valor bruto da nota sobre cupom (D2_VALBRUT)
			nVldTot := ValBruto()
		EndIf

		// No padrão o sistema está carregando incorretamente informações de emissão da NFC-e para a NF-e de acobertamento
		RecLock("SF2",.F.)
		SF2->F2_DTDIGIT := dDataBase
		SF2->F2_DAUTNFE := CToD("")
		SF2->F2_HAUTNFE	:= Space(TamSX3("F2_HAUTNFE")[1])
		////PABLO: ajusto o [VALOR TOTAL DA NOTA] para ficar igual ao [VALOR TOTAL DOS PRODUTOS]
		If nVldTot > 0 .and. SF2->F2_VALBRUT <> nVldTot
			SF2->F2_VALBRUT := nVldTot
		EndIf
		SF2->(MsUnlock())

		//DANILO: limpo campo, pois da erro quando tem mais de uma NFCe sendo emitida
		RecLock("SF3",.F.)
		SF3->F3_OBSERV	:= ""
		SF3->(MsUnLock())

	EndIf

	RestArea(aAreaMDL)
	RestArea(aArea)

Return

/*/{Protheus.doc} ValBruto
Total dos cupons que compoem a nota sobre cupom

@type function
@version 12.1.25
@author Pablo Nunes
@since 12/07/2021
@return numeric, valor bruto com o total dos cupons
/*/
Static Function ValBruto()

	Local nVldTot := 0
	Local cQry := ""

	If Select("QRYSD2") > 0
		QRYSD2->(DbCloseArea())
	Endif

	cQry := "SELECT SUM(D2_TOTAL) as VLDTOT "
	cQry += " FROM "+RetSqlName("SD2")+" SD2 "
	cQry += " INNER JOIN "+RetSqlName("MDL")+" MDL ON ( "
	cQry += " 	MDL.D_E_L_E_T_ = SD2.D_E_L_E_T_ "
	cQry += " 	AND MDL_FILIAL = SD2.D2_FILIAL "
	cQry += " 	AND MDL.MDL_CUPOM = SD2.D2_DOC "
	cQry += " 	AND MDL_SERCUP = SD2.D2_SERIE "
	cQry += " 	) "
	cQry += " WHERE SD2.D_E_L_E_T_ = ' ' "
	cQry += " 	AND MDL_FILIAL = '"+SF2->F2_FILIAL+"' "
	cQry += " 	AND MDL_NFCUP = '"+SF2->F2_DOC+"' "
	cQry += " 	AND MDL_SERIE = '"+SF2->F2_SERIE+"' "

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYSD2"

	If QRYSD2->(!EOF())
		nVldTot := QRYSD2->VLDTOT
	EndIf

	QRYSD2->(DbCloseArea())

Return nVldTot

/*/{Protheus.doc} AjSD2ValBrut
Ajusta o valor bruto da nota sobre cupom (D2_VALBRUT)

@type function
@version 12.1.25
@author Pablo Nunes
@since 03/09/2021
/*/
Static Function AjSD2ValBrut()

	Local aArea := GetArea()
	Local aAreaSD2 := SD2->(GetArea())
	Local cQry := ""

	If Select("QRYSD2") > 0
		QRYSD2->(DbCloseArea())
	Endif

	cQry := " SELECT SD2_NF.R_E_C_N_O_ as SD2NFRECNO, SD2_CUP.R_E_C_N_O_ as SD2CUPRECNO, "
	cQry += " 	SD2_CUP.D2_TOTAL AS CUP_D2_TOTAL "
	cQry += " FROM "+RetSqlName("SD2")+" SD2_NF "
	cQry += " INNER JOIN "+RetSqlName("SD2")+" SD2_CUP ON ( "
	cQry += " 	SD2_CUP.D_E_L_E_T_ = SD2_NF.D_E_L_E_T_ "
	cQry += " 	AND SD2_CUP.D2_FILIAL = SD2_NF.D2_FILIAL "
	cQry += " 	AND SD2_CUP.D2_SERIORI = SD2_NF.D2_SERIE "
	cQry += " 	AND SD2_CUP.D2_ITEMORI = SD2_NF.D2_ITEM "
	cQry += " 	AND SD2_CUP.D2_NFCUP = SD2_NF.D2_DOC "
	cQry += " 	AND SD2_CUP.D2_COD = SD2_NF.D2_COD "
	cQry += " 	AND SD2_CUP.D2_QUANT = SD2_NF.D2_QUANT "
	cQry += " 	) "
	cQry += " WHERE SD2_NF.D_E_L_E_T_ = ' ' "
	cQry += " 	AND SD2_NF.D2_FILIAL = '"+SF2->F2_FILIAL+"' "
	cQry += " 	AND SD2_NF.D2_DOC = '"+SF2->F2_DOC+"' "
	cQry += " 	AND SD2_NF.D2_SERIE = '"+SF2->F2_SERIE+"' "
	cQry += " 	AND (SD2_CUP.D2_TOTAL <> SD2_NF.D2_VALBRUT OR SD2_CUP.D2_TOTAL <> SD2_CUP.D2_VALBRUT) " //valor total diferente do total bruto da NOTA SOBRE CUPOM

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYSD2"

	QRYSD2->(DbGoTop())
	While QRYSD2->(!EOF())

		SD2->(DbGoTo(QRYSD2->SD2NFRECNO))
		If SD2->(!EOF()) .and. SD2->D2_VALBRUT <> QRYSD2->CUP_D2_TOTAL
			RecLock("SD2",.F.)
			SD2->D2_VALBRUT	:= QRYSD2->CUP_D2_TOTAL
			SD2->(MsUnLock())
		EndIf

		SD2->(DbGoTo(QRYSD2->SD2CUPRECNO))
		If SD2->(!EOF()) .and. SD2->D2_VALBRUT <> QRYSD2->CUP_D2_TOTAL
			RecLock("SD2",.F.)
			SD2->D2_VALBRUT	:= QRYSD2->CUP_D2_TOTAL
			SD2->(MsUnLock())
		EndIf

		QRYSD2->(DbSkip())
	EndDo

	QRYSD2->(DbCloseArea())

	RestArea(aAreaSD2)
	RestArea(aArea)

Return
