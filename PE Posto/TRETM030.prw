#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETM030
Ponto de Entrada da Rotina de Cadastro de Tabela de Preço Base.

@author Pablo Cavalante
@since 19/02/2020
@version 1.0
@return Nil
@type function
/*/
User Function TRETM030()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj
	Local cOperad	 := ''
	Local oModelU0B, oModelU0C
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local cClasse    := ''
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local nX

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
		cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' )

		lIsGrid    := ( Len( aParam ) > 3 ) .and. cClasse == 'FWFORMGRID'

		If lIsGrid
			nQtdLinhas := oObj:Length()
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

			If oObj:GetOperation() = 4 // se a operação for alteração ( 4 - Update )
				xRet := FORMCOMMITTTSPRE(oObj,lIsGrid) // função que grava o histório na tabela U0G
			EndIf

		ElseIf cIdPonto == 'FORMCOMMITTTSPOS'

		ElseIf cIdPonto == 'MODELCOMMITTTS'

		ElseIf cIdPonto == 'MODELCOMMITNTTS'

			//Envio os registros para os PDVs
			If oObj:GetOperation() == 3 // inclusão
				cOperad := "I"
			ElseIf oObj:GetOperation() == 4 //alteração
				cOperad := "A"
			ElseIf oObj:GetOperation() == 5  //exclusão
				cOperad := "E"
			EndIf

			//Tabela de Preco Base
			oModelU0B := oObj:GetModel( 'U0BMASTER' ) 
			//U0B_FILIAL+U0B_PRODUT
			U_UREPLICA("U0B", 1, xFilial("U0B") + oModelU0B:GetValue('U0B_PRODUT'), cOperad)

			//Itens Tabela de Preco Base
			oModelU0C := oObj:GetModel( 'U0CDETAIL' ) 
			//U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
			For nX := 1 To oModelU0C:Length()
				oModelU0C:Goline(nX) // posiciono na linha atual
				If oModelU0C:IsDeleted(nX)
					U_UREPLICA("U0C",1,xFilial("U0C") + oModelU0B:GetValue('U0B_PRODUT') + oModelU0C:GetValue('U0C_FORPAG') + oModelU0C:GetValue('U0C_CONDPG') + oModelU0C:GetValue('U0C_ADMFIN') , "E")
				Else
					U_UREPLICA("U0C",1,xFilial("U0C") + oModelU0B:GetValue('U0B_PRODUT') + oModelU0C:GetValue('U0C_FORPAG') + oModelU0C:GetValue('U0C_CONDPG') + oModelU0C:GetValue('U0C_ADMFIN') , cOperad)
				endif
			Next nX

		ElseIf cIdPonto == 'MODELCANCEL'

		EndIf

	EndIf

Return xRet

/*/{Protheus.doc} FORMCOMMITTTSPRE
Chamada antes da gravação da tabela do formulário (FORMCOMMITTTSPRE).

@author Pablo
@since 19/02/2020

@version 1.0
@return Nil
@param oObj, object, descricao
@type function
/*/
Static Function FORMCOMMITTTSPRE(oObj,lIsGrid)

	Local oModelU0C := iif(lIsGrid,oObj,oObj:GetModel('U0CDETAIL'))
	Local aArea     := GetArea()
	Local aAreaU0B	:= U0B->(GetArea())
	Local aAreaU0C	:= U0C->(GetArea())
	Local nX := 0

	U0C->(DbSetOrder(1)) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN

	If oObj:GetOperation() == 4 // se a operação for alteração ( 4 - Update )

		For nX := 1 To oModelU0C:Length() // retorna a quantidade de linhas que o grid possui

			oModelU0C:Goline(nX) // altera a linha em que o Grid está posicionado, mesmo se a linha atual estiver invalida

			If oModelU0C:IsUpdated(nX) // indica se a linha recebeu valores

				If U0C->(DbSeek( xFilial("U0C") + oModelU0C:GetValue('U0C_PRODUT') + oModelU0C:GetValue('U0C_FORPAG') + oModelU0C:GetValue('U0C_CONDPG') + oModelU0C:GetValue('U0C_ADMFIN') ))
					GrvLogU0G()
				EndIf

			EndIf

		Next nX

	EndIf

	RestArea( aAreaU0B )
	RestArea( aAreaU0C )
	RestArea( aArea )

Return NIL

/*/{Protheus.doc} GrvLogU0G
Grava a tsbela U0G -> Hist. Itens Tabela de P. Base

@author Pablo
@since 19/02/2020

@version 1.0
@return Nil
@param oObj, object, descricao
@type function
/*/
Static Function GrvLogU0G()

	Local aCampos := FWSX3Util():GetAllFields( "U0C", .F. )
	Local nX

	aSort(aCampos)

	//grava o histórico somente de um preço base que esta ativo
	If (DtoS(Date()) + SubStr(Time(),1,TamSX3("U0C_HRINIC")[01])) >= (DtoS(U0C->U0C_DTINIC) + U0C->U0C_HRINIC)

		U0G->(DbSetOrder(1)) //U0G_FILIAL+U0G_PRODUT+U0G_FORPAG+U0G_CONDPG+U0G_ADMFIN+DTOS(U0G_DTINIC)+U0G_HRINIC
		If U0G->(DbSeek(U0C->(U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN+DTOS(U0C_DTINIC)+U0C_HRINIC)))

			RecLock("U0G",.F.)

			U0G->U0G_USHIST := RetCodUsr() // Usuario Inclusao
			U0G->U0G_DTHIST := Date() // Data Inclusao
			U0G->U0G_HRHIST := Time() // Hora Inclusao

			U0G->(MsUnlock())

		Else

			RecLock("U0G",.T.)

			For nX := 1 to Len(aCampos)
				&("U0G->U0G"+SubStr(aCampos[nX],4,7)) := &("U0C->"+aCampos[nX])
			Next nX

			U0G->U0G_USHIST := RetCodUsr() // Usuario Inclusao
			U0G->U0G_DTHIST := Date() // Data Inclusao
			U0G->U0G_HRHIST := Time() // Hora Inclusao

			U0G->(MsUnlock())

		EndIf

	EndIf

Return NIL


