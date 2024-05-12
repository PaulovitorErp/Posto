#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} MT120ALT
Ponto de Entrada utilizado para validar o registro posicionado do PC e retornar .T.
se deve continuar e executar as opera��es de inclus�o, altera��o, exclus�o e c�pia
ou retornar .F. para interromper o processo
@author Wellington Gon�alves
@since 01/05/2015
@version 1.0
@return l�gico
@type function
/*/

User Function MT120ALT()

	Local _nOpc	:= Paramixb[1]
	Local _lRet := .T.
	Local cMV_XPECRC := SuperGetMv("MV_XPECRC",,"2") //Qual PE usar para CRC: 1-Sigaloja;2=TotvsPDV

	/////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
	/////////////////////////////////////////////////////////////////////////////////////////
	If cMV_XPECRC == "2" .AND. ExistBlock("TRETP005")
		_lRet := Execblock("TRETP005",.F.,.F.,{_nOpc})
	EndIf

Return _lRet
