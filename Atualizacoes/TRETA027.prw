#include 'protheus.ch'
#include 'fwmvcdef.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TRETA027
Manutenção de Bombas
@author TOTVS
@since 10/04/2014
@version P12
@param Nao recebe parametros
@return nulo
/*/
User Function TRETA027()

	Local oBrowse

	Private aRotina := {}
	Private cCadastro

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias("U00")
	oBrowse:SetDescription("Manutenção de Bombas")
	oBrowse:Activate()

Return Nil

Static Function MenuDef()

	aRotina 	:= {}
	cCadastro	:=""

	ADD OPTION aRotina Title 'Visualizar'	Action "VIEWDEF.TRETA027"	OPERATION 2 ACCESS 0
	ADD OPTION aRotina Title "Incluir"    	Action "VIEWDEF.TRETA027"	OPERATION 3 ACCESS 0
	ADD OPTION aRotina Title "Excluir"      Action "VIEWDEF.TRETA027" 	OPERATION 5 ACCESS 0
	ADD OPTION aRotina Title "Vinc.Imagem"	Action "MsDocument" 		OPERATION 6 ACCESS 0

Return aRotina

Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU00 := FWFormStruct(1,"U00",/*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU01 := FWFormStruct(1,"U01",/*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU02 := FWFormStruct(1,"U02",/*bAvalCampo*/,/*lViewUsado*/ )

	Local oModel
	Local bLinePost := {|| U_U02ENC() }

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New("TRETM027",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields("U00MASTER",/*cOwner*/,oStruU00)

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({"U00_NUMSEQ"}) //"U00_FILIAL",

	// Adiciona ao modelo uma estrutura de formulário de edição por grid
	oModel:AddGrid("U01DETAIL","U00MASTER",oStruU01,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*BLoad*/)
	oModel:AddGrid("U02DETAIL","U00MASTER",oStruU02,/*bLinePre*/,bLinePost,/*bPreVal*/,/*bPosVal*/,/*BLoad*/)

	// Faz relaciomaneto entre os compomentes do model
	oModel:SetRelation("U01DETAIL", {{"U01_FILIAL", 'xFilial("U01")'},{"U01_NUMSEQ","U00_NUMSEQ"}},U01->(IndexKey(1)))
	oModel:SetRelation("U02DETAIL", {{"U02_FILIAL", 'xFilial("U02")'},{"U02_NUMSEQ","U00_NUMSEQ"}},U02->(IndexKey(1)))

	// Desobriga a digitacao de ao menos um item
	oModel:GetModel("U02DETAIL"):SetOptional(.T.)

	// Liga o controle de nao repeticao de linha
	oModel:GetModel("U01DETAIL"):SetUniqueLine({"U01_LACRE"})
	oModel:GetModel("U02DETAIL"):SetUniqueLine({"U02_BICO"})

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription("Manutenção de Bombas")

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel("U00MASTER"):SetDescription("Dados Manutenção")
	oModel:GetModel("U01DETAIL"):SetDescription("Dados Lacres")
	oModel:GetModel("U02DETAIL"):SetDescription("Dados Bicos")

Return oModel

Static Function ViewDef()

	// Cria a estrutura a ser usada na View
	Local oStruU00 := FWFormStruct(2,"U00")
	Local oStruU01 := FWFormStruct(2,"U01")
	Local oStruU02 := FWFormStruct(2,"U02")

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel("TRETA027")
	Local oView

	// Remove campos da estrutura
	oStruU01:RemoveField('U01_NUMSEQ')
	oStruU02:RemoveField('U02_NUMSEQ')

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField("VIEW_U00",oStruU00,"U00MASTER")

	//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	oView:AddGrid("VIEW_U01",oStruU01,"U01DETAIL")
	oView:AddGrid("VIEW_U02",oStruU02,"U02DETAIL")

	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox("EMCIMA" , 30)
	oView:CreateHorizontalBox("MEIO"   , 20)
	oView:CreateHorizontalBox("EMBAIXO", 50)

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView("VIEW_U00","EMCIMA")
	oView:SetOwnerView("VIEW_U01","MEIO")
	oView:SetOwnerView("VIEW_U02","EMBAIXO")

	// Liga a identificacao do componente
	oView:EnableTitleView("VIEW_U00")
	oView:EnableTitleView("VIEW_U01","Dados Lacres",RGB(224,30,43))
	oView:EnableTitleView("VIEW_U02","Manutenção Bicos",0 )

	// Define campos que terao Auto Incremento
	oView:AddIncrementField("VIEW_U02","U02_SEQBIC")
	oView:SetCloseOnOk( {||.T.} )

Return oView

User Function U02ENC()

	Local lRet			:= .T.

	// Valida se o encerrante atual é inferior ao encerrante anterior
	If FwFldGet("U02_ENCATU") <> 0 .And. FwFldGet("U02_ENCATU") < FwFldGet("U02_ENCANT")
		lRet := .F.
		Help(,,'Help',,"O campo <Encerrante atual> não pode ser inferior ao campo <Encerrante anterior>," + CRLF + ;
		"com exceção de 0 (zero) em caso de Troca de Placa.",1,0)
	Endif

Return lRet

User Function GETU0X()

	Local oModel     := FWModelActive()
	Local oView 	 := FWViewActive()
	Local nOperation := oModel:GetOperation()
	Local oModelU00  := oModel:GetModel( 'U00MASTER' )
	Local oModelU01  := oModel:GetModel( 'U01DETAIL' )
	Local oModelU02  := oModel:GetModel( 'U02DETAIL' )
	Local nLinha     := 0
	Local cBomba     := oModel:GetValue( 'U00MASTER', 'U00_BOMBA' )
	Local dDataInt   := oModel:GetValue( 'U00MASTER', 'U00_DTINT' )
	Local _aArea     := GetArea()
	Local nZ

	If nOperation == 3

		oModelU00:Activate()
		oModelU01:Activate()
		oModelU02:Activate()

		//Preenche com os dados novos
		//LACRES
		cQry:="SELECT * FROM " + RetSqlName("MIB")
		cQry+=" WHERE D_E_L_E_T_='' AND MIB_CODBOM='"+cBomba+"' AND MIB_FILIAL='"+xFilial("MIB")+"' AND MIB_DTINAT=' ' ORDER BY R_E_C_N_O_ DESC"

		If Select("TRETA027")>0
			TRETA027->(DbCloseArea())
		Endif
		cQry := ChangeQuery(cQry)
		Tcquery cQry New Alias "TRETA027"

		u_ClearAcolsMVC(oModelU01,oView)
		u_ClearAcolsMVC(oModelU02,oView)

		While TRETA027->(!Eof())

			nLinha++
			If nlinha == 1 //(oModelU01:GetValue('U01_LACRE'))
				oModelU01:SetValue( 'U01_LACRE'   , TRETA027->MIB_NROLAC )
			Else
				If oModelU01:AddLine() == nLinha
					oModelU01:GoLine( nLinha )
					oModelU01:SetValue( 'U01_LACRE'   , TRETA027->MIB_NROLAC )
				Endif
			Endif
			TRETA027->(DbSkip())

		Enddo

		TRETA027->(DbCloseArea())

		oModelU01:GoLine( 1 )

		//BICOS
		cQry:="SELECT * FROM " + RetSqlName("MIC")
		cQry+=" WHERE D_E_L_E_T_='' AND MIC_CODBOM='"+cBomba+"' AND MIC_FILIAL='"+xFilial("MIC")+"'"
		cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+DToS(dDataInt)+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+DToS(dDataInt)+"'))"

		If Select("TRETA027A")>0
			TRETA027A->(DbCloseArea())
		Endif
		cQry := ChangeQuery(cQry)
		Tcquery cQry New Alias "TRETA027A"

		nZ := 0

		While TRETA027A->(!Eof())

			cQry:="SELECT MAX(MID_ENCFIN) AS ENCANT"
			cQry+=" FROM "+RetSqlName("MID")+" MID "
			cQry+=" WHERE MID.D_E_L_E_T_<>'*' "
			cQry+=" AND MID_FILIAL = '"+xFilial("MID")+"' "
			cQry+=" AND MID_DATACO = '"+DToS(dDataInt)+"' "
			cQry+=" AND MID_CODBIC = '"+AllTrim(TRETA027A->MIC_CODBIC)+"' "
			cQry+=" AND MID_CODTAN = '"+AllTrim(TRETA027A->MIC_CODTAN)+"' "
			cQry+=" AND MID_XDIVER = '1' " //Não divergente
			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "TRETA027B"

			nZ++

			If nZ == 1

				oModelU02:LoadValue( 'U02_BICO'   	, TRETA027A->MIC_CODBIC )
				oModelU02:LoadValue( 'U02_NUMLOG'  	, TRETA027A->MIC_NLOGIC )
				oModelU02:SetValue('U02_ENCANT', TRETA027B->ENCANT)
				
			Else

				If Empty(oModelU02:GetValue('U02_BICO'))

					oModelU02:SetValue('U02_BICO'   	, TRETA027A->MIC_CODBIC)
					oModelU02:SetValue('U02_NUMLOG'  	, TRETA027A->MIC_NLOGIC)
					oModelU02:SetValue('U02_ENCANT' 	, TRETA027B->ENCANT)

				Else

					If oModelU02:AddLine() == nZ //nLinha

						oModelU02:GoLine( nZ ) //nLinha
						oModelU02:LoadValue('U02_BICO'   	, TRETA027A->MIC_CODBIC)
						oModelU02:LoadValue('U02_NUMLOG'  	, TRETA027A->MIC_NLOGIC)
						oModelU02:SetValue('U02_ENCANT'   , TRETA027B->ENCANT)

					Endif
				Endif
			Endif

			TRETA027B->(DbCloseArea())

			TRETA027A->(DbSkip())
		Enddo

		TRETA027A->(DbCloseArea())

		RestArea(_aArea)

		oModelU02:Goline(1)
		oView:Refresh()
	Endif

Return .T.
