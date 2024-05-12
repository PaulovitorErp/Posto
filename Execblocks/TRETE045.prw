#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETE045
Exclui as vendas: STATUS com "XS" ou "XR" - Cancelamento de Vendas
XS -> exclui tudo (todas tabelas)
XR -> venda fica com status de "CANCELADO" (mantem SFT e SF3)

Ex.:

;JOB DE CANCELAMENTO DE VENDAS (POSTO INTELIGENTE: Status "XS" ou "XR")
[U_TRETE045]
Main=U_TRETE022
Environment=HOSTS
nParms=4
Parm1=TRETE045
Parm2=01
Parm3=0101,0201
Parm4=2000

@type function
@version 12.1.25
@author Pablo Nunes
@since 28/10/2021
/*/
User Function TRETE045(cEmpX, cFilX)

Local cQrySL1 := ""

Local cDescMot := "" // Descricao do motivo
Local xRet // Retorno da funcao
Local lGeraNCC := .F. // Numero da Ncc gerada
Local cNumNFDev := "" // Numero da nota fiscal de devolucao
Local cSerieDev := "" // Serie de devolucao
Local cMotivo := "" // Motivo da devolucao
Local cNum := "" // numero do orçamento
Local lNFCe := .T. // ExistFunc("LjEmitNFCe") .AND.  LjEmitNFCe() .AND. ColumnPos("L1_KEYNFCE") > 0
Local lLstPre := .F. // indica contem um item de Lista de Presente
Local cProtoNfce  := ""
Local cSitua := ""

//cEmpAnt := cEmpX
//cFilAnt := cFilX

//SET DATE FORMAT TO "dd/mm/yyyy"
//SET CENTURY ON
//SET DATE BRITISH

//RpcSetType(3)
//RpcClearEnv()  //-- Limpa ambiente
//RpcSetEnv(cEmpAnt, cFilAnt)

	cQrySL1 := "select SL1.R_E_C_N_O_ as SL1RECNO"
	cQrySL1 += " from " + retsqlname('SL1') + " SL1"
	cQrySL1 += " where SL1.D_E_L_E_T_ = ' '"
	cQrySL1 += " and SL1.L1_FILIAL = '"+xFilial("SL1")+"'"
	cQrySL1 += " and SL1.L1_SITUA in ('XS','XR')" // STATUS: XS e XR - Cancelamento de Vendas
	//cQrySL1 += " and SL1.L1_STATUS = 'P2K'"
	//cQrySL1 += " and L1_DESPESA > 0"
	//cQrySL1 += " and L1_DOC = '000233200' and L1_SERIE = '053'" //TODO: debug
	cQrySL1 += " order by SL1.L1_FILIAL, SL1.L1_EMISNF"

	If Select("T_SL1")>0
		T_SL1->(DbCloseArea())
	EndIf

	cQrySL1 := ChangeQuery(cQrySL1)
	TcQuery cQrySL1 New Alias "T_SL1" // Cria uma nova area com o resultado do query

	DbSelectArea("T_SL1")
	T_SL1->(DbGoTop())
	If T_SL1->(!Eof())

		While T_SL1->(!Eof())

			SL1->(DbGoTo(T_SL1->SL1RECNO))
			cSitua := SL1->L1_SITUA
			
			If cFilAnt <> SL1->L1_FILIAL
				cFilAnt := SL1->L1_FILIAL
				U_AjustaSM0()
			EndIf

			cNum := SL1->L1_NUM
			cNfFis := SL1->L1_DOC
			cSerie := SL1->L1_SERIE

			RecLock("SL1",.F.)
				SL1->L1_SITUA := 'X2'
			SL1->(MsUnlock())

			SF2->(dbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			SF2->(dbSeek(xFilial("SF2") + SL1->L1_DOC + SL1->L1_SERIE + SL1->L1_CLIENTE + SL1->L1_LOJA))

			//LjGrvLog( SL1->L1_NUM, "lj140Exc | Antes de enviar para Lj140Grava",)
			xRet := Lj140Grava(.T., cDescMot, lGeraNCC, cNumNFDev, cSerieDev, cMotivo, cNum, lNFCe, lLstPre, cProtoNfce)
			//LjGrvLog( SL1->L1_NUM, "lj140Exc | Apos de enviar para Lj140Grava | xRet: " + cValToChar( xRet ) , )

			If xRet .and. cSitua == 'XS' //Caso XR não exclui os dados fiscais

				SFT->(DbSetOrder(1)) //FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
				If SFT->(DbSeek(xFilial("SFT")+'S'+cSerie+cNfFis))
					While SFT->(!Eof()) .and. (xFilial("SFT")+'S'+cSerie+cNfFis) == SFT->(FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL)
						RecLock("SFT",.F.)
							SFT->(DbDelete())
						SFT->(MsUnlock())
						SFT->(DbSkip())
					EndDo
				EndIf

				SF3->(DbSetOrder(5)) //F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT
				If SF3->(DbSeek(xFilial("SF3")+cSerie+cNfFis))
					While SF3->(!Eof()) .and. (xFilial("SF3")+cSerie+cNfFis) == SF3->(F3_FILIAL+F3_SERIE+F3_NFISCAL)
						RecLock("SF3",.F.)
							SF3->(DbDelete())
						SF3->(MsUnlock())
						SF3->(DbSkip())
					EndDo
				EndIf

				MEP->(DbSetOrder(1)) //MEP_FILIAL+MEP_PREFIX+MEP_NUM+MEP_PARCEL+MEP_TIPO+MEP_PARTEF
				If MEP->(DbSeek(xFilial("MEP")+cSerie+cNfFis))
					While MEP->(!Eof()) .and. (xFilial("MEP")+cSerie+cNfFis) == MEP->(MEP_FILIAL+MEP_PREFIX+MEP_NUM)
						RecLock("MEP",.F.)
							MEP->MEP_PARCEL := ""
							MEP->(DbDelete())
						MEP->(MsUnlock())
						MEP->(DbSkip())
					EndDo
				EndIf

			EndIf
		
			T_SL1->(DbSkip())
		EndDo

	EndIf

	T_SL1->(DbCloseArea())

Return
