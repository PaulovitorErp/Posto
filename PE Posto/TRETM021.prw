#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETM021
Ponto de Entrada da Rotina de Cadastro de Negociação de Pagamento: Forma de Pagto x Cond de Pagto (TRETA021).

@author Pablo Cavalcante
@since 07/05/2015
@version 1.0
@return Nil
@type function
/*/
User Function TRETM021()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local cClasse    := ''
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local cMsg       := ''

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
		cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' )

		lIsGrid    := ( Len( aParam ) > 3 ) .and. cClasse == 'FWFORMGRID'

		If lIsGrid
			nQtdLinhas := oObj:GetQtdLine()
			nLinha     := oObj:nLine
		EndIf

		If cIdPonto == 'MODELVLDACTIVE'

		ElseIf cIdPonto == 'BUTTONBAR'

		ElseIf cIdPonto == 'FORMLINEPRE'

		ElseIf cIdPonto ==  'FORMPRE'

		ElseIf cIdPonto == 'FORMPOS'

		ElseIf cIdPonto == 'FORMLINEPOS'

		ElseIf cIdPonto ==  'MODELPRE'

		ElseIf cIdPonto == 'MODELPOS'

		ElseIf cIdPonto == 'FORMCOMMITTTSPRE'

		ElseIf cIdPonto == 'FORMCOMMITTTSPOS'

		ElseIf cIdPonto == 'MODELCOMMITTTS'

		ElseIf cIdPonto == 'MODELCOMMITNTTS'

			MODELCOMMITNTTS(oObj)

		ElseIf cIdPonto == 'MODELCANCEL'

		EndIf

	EndIf

Return xRet

//
// Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS).
//
Static Function MODELCOMMITNTTS(oObj)

	Local oModelU44	:= oObj:GetModel( 'U44MASTER' )
	Local aArea     := GetArea()
	Local aAreaU44	:= U44->(GetArea())
	Local cOperad	:= ""
	Local cForma    := U44->U44_FORMPG
	Local cCond     := U44->U44_CONDPG

	//COMENTADO: campo foi liberado para edição e criados gatilhos sugerindo nome
	//gera a descrição
	//DbSelectArea( "U44" )
	//RecLock( "U44", .F. )
	//	U44->U44_DESCRI := alltrim(posicione("SX5",1,xFilial("SX5")+"24"+U44->U44_FORMPG,"X5_DESCRI")) + " " + alltrim(posicione("SE4",1,xFilial("SE4")+U44->U44_CONDPG,"E4_DESCRI"))
	//U44->( msUnlock() )

	// envio o registro para retaguarda e/ou PDV
	If oObj:GetOperation() == 3 // inclusão
		cOperad := "I"
	ElseIf oObj:GetOperation() == 4 //alteração
		cOperad := "A"
	ElseIf oObj:GetOperation() == 5  //exclusão
		cOperad := "E"
	EndIf

	//U44_FILIAL+U44_FORMPG+U44_CONDPG
	U_UREPLICA( "U44", 1, xFilial("U44")+oModelU44:GetValue('U44_FORMPG')+oModelU44:GetValue('U44_CONDPG'), cOperad )

	RestArea( aAreaU44 )
	RestArea( aArea )

Return NIL
