#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETA008
Cadastro de Abastecimentos.

@author pablo
@since 16/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA008()

	Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( "MID" )
	oBrowse:SetDescription( 'Tabela de Abastecimentos' )

	oBrowse:Activate()

Return NIL


//-------------------------------------------------------------------
Static Function MenuDef()

	Local aRotina 	:= {}

	ADD OPTION aRotina Title 'Pesquisar'  				Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar' 				Action 'VIEWDEF.TRETA008' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'					Action 'VIEWDEF.TRETA008' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    				Action 'VIEWDEF.TRETA008' 	OPERATION 08 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     				Action 'VIEWDEF.TRETA008' 	OPERATION 05 ACCESS 0

Return aRotina


//-------------------------------------------------------------------
Static Function ModelDef()

	Local oStruMID := FWFormStruct( 1, "MID", /*bAvalCampo*/, /*lViewUsado*/ )
    Local oModel

// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM008', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'MIDMASTER', /*cOwner*/, oStruMID )

// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Tabela de Abastecimentos' )

// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "MID_FILIAL" , "MID_CODABA" })

// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'MIDMASTER' ):SetDescription( 'Dados do Abastecimento' )

// Adiciona validação ao campo de bico
	oStruMID:SetProperty('MID_CODBIC', MODEL_FIELD_VALID, {|| U_TRETA08A() } )

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

	Local oStruMID := FWFormStruct( 2, "MID" )
	Local oModel   := FWLoadModel( 'TRETA008' )
	Local oView

// Cria o objeto de View
	oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

// Crio um agrupador de campos
	oStruMID:AddGroup( 'GRUPO01', 'Dados do Bico', '', 2 )
	oStruMID:AddGroup( 'GRUPO02', 'Dados do Abastecimento', '', 2 )

// Colocando todos os campos para o agrupamento 2
	oStruMID:SetProperty( '*' , MVC_VIEW_GROUP_NUMBER, 'GRUPO02' )

// Trocando os campos do bico para o agrupamento 1
	oStruMID:SetProperty( 'MID_CODTAN'	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
	oStruMID:SetProperty( 'MID_CODBOM'	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
	oStruMID:SetProperty( 'MID_CODBIC' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
	oStruMID:SetProperty( 'MID_NLOGIC' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
	oStruMID:SetProperty( 'MID_LADBOM'	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
	oStruMID:SetProperty( 'MID_XCONCE'	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_MID', oStruMID, 'MIDMASTER' )

// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )

// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_MID', 'SUPERIOR' )

Return oView

/*/{Protheus.doc} TRETA08A
Valida se o bico poderá ser utilizado para inclusão/alteração de abastecimento manual.

@type function
@version 1
@author pablo
@since 08/04/2021
@return boolean, informação valida ou não
/*/
User Function TRETA08A()

	Local oModelDad  := FWModelActive()
	Local lRet := .T.
	Local cCodBico := ""
	Local lBicoAtivo := .F.

	If !IsBlind()
		If AllTrim(ReadVar()) = "M->MID_CODBIC"
			
            cCodBico := oModelDad:GetValue('MIDMASTER', "MID_CODBIC") //M->MID_CODBIC

            DbSelectArea("MIC")
            MIC->(DbSetOrder(1)) //MIC_FILIAL+MIC_CODBIC+MIC_CODBOM
            If !MIC->(DbSeek(xFilial("MIC") + cCodBico))
                Help( ,, 'HELP',, 'Bico não cadastrado.', 1, 0)
                lRet:= .F.
            EndIf

			if lRet
				lBicoAtivo := .F.
				While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_CODBIC == xFilial("MIC") + cCodBico
					//se bico ativo, considero
					If ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))
						lBicoAtivo := .T.
						EXIT
					endif
					MIC->(DbSkip())
				enddo
				If !lBicoAtivo
					Help( ,, 'HELP',, 'Bico inativado.', 1, 0)
					lRet := .F.
				EndIf
			endif

			If lRet .and. !Empty(cCodBico) .and. MIC->(FieldPos("MIC_XBABMA")) > 0
				If MIC->MIC_XBABMA == "S" // S - BLOQUEIO ABASTECIMENTO MANUAL
                    Help( ,, 'HELP',, 'Bico com bloqueio para abastecimento manual.', 1, 0)
					lRet := .F.
				EndIf
			EndIf

		EndIf
	EndIf

Return lRet

