
#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP025 (StiCusSFil)
No fonte "StiCustomerSelection" foi acrescentado o PE com a funcionalidade citada, 
com o nome temporário de "StiCusSFil", estará posicionado na tabela "SA1" no registro a ser analisado, 
o retorno esperado pela User Function é um vetor contendo:
[01] - Bloco de codigo com expressão ADVPL
[02] - Expressão string em ADVPL equivalente a do bloco de código

O retorno será avaliado em cada parte do fonte como ".T." será descartado o registro em questão que atenda a expressão ADVPL

@author pablo
@since 09/10/2019
@version 1.0
@return xRet
@type function
/*/
User Function TPDVP025()

	Local bFiltro := {||}
	Local cFiltro := ""
	Local aRet := {{|| .F. }, ".F."}
	Local lBlqAI0 := SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local lSQLite := AllTrim(Upper(GetSrvProfString("RpoDb",""))) == "SQLITE" //Banco de Dados SQLite

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente)
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return aRet
    EndIf

// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
	If lBlqAI0
		bFiltro := {|| Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')=='S' }
		If lSQLite //AI0_FILIAL+AI0_CODCLI+AI0_LOJA
			cFiltro := " and exists (select 1 from " + RetSqlName("AI0") + " AI0 where AI0.D_E_L_E_T_ = '' and AI0_FILIAL = '" + xFilial('AI0') + "' and AI0_CODCLI = A1_COD and AI0_LOJA = A1_LOJA and AI0_XBLFIL <> 'S')"
		Else
			cFiltro := " .and. Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')<>'S'"
		EndIf
		aRet := { bFiltro, cFiltro }

	ElseIf SA1->(FieldPos("A1_XFILBLQ")) > 0
		bFiltro := {|| !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ) }
		If lSQLite
			cFiltro := " and ((A1_XFILBLQ = '') or (A1_XFILBLQ not like '%"+cFilAnt+"%'))"
		Else
			cFiltro := " .and. (Empty(SA1->A1_XFILBLQ) .or. !(cFilAnt $ SA1->A1_XFILBLQ))"
		EndIf
		aRet := { bFiltro, cFiltro }

	EndIf

Return aRet
