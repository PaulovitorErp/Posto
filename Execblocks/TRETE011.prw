#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETE011
Habilita/Desabilita os gets da página do LMC, conforme o produto selecionado
@author Maiki Perin
@since 08/11/2018
@version 1.0
@param cCampo
@return nulo
/*/

/*****************************/
User Function TRETE011(cCampo)
/*****************************/

Local lRet 		:= .F.

Local aArea		:= GetArea()
Local aAreaSB2	:= SB2->(GetArea())
Local aAreaMHZ	:= MHZ->(GetArea())

SB2->(DbSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL
SB2->(DbGoTop())

If !Empty(cProd)

	If SB2->(DbSeek(xFilial("SB2")+cProd))
	
		While SB2->(!EOF()) .And. xFilial("SB2") + cProd == SB2->B2_FILIAL + SB2->B2_COD
			
			//Tanque relacionado
			MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
			MHZ->(DbGoTop())
			If MHZ->(DbSeek(xFilial("MHZ")+SB2->B2_COD+SB2->B2_LOCAL)) 
				While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+SB2->B2_COD+SB2->B2_LOCAL 
					//If MHZ->MHZ_STATUS == "1" //Ativo
					If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= FwFldGet("MIE_DATA")) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= FwFldGet("MIE_DATA")))
						If SubStr(cCampo,9,2) == MHZ->MHZ_CODTAN
							lRet := .T.
							Exit
						Endif
					Endif
					MHZ->(DbSkip())
				Enddo
				if lRet 
					Exit
				endif
			Endif
			
			SB2->(DbSkip())
		EndDo
	Endif
Endif

RestArea(aAreaSB2)
RestArea(aAreaMHZ)
RestArea(aArea)

Return lRet
