#Include "Protheus.ch"
#Include "RWMAKE.CH"

/*/{Protheus.doc} TRETP038
Chamado pelo P.E. CRM980MDEF para adicionar rotinas no Cadastro de Clientes (CRMA980)

@author TBC
@since 29/11/2018
@version 1.0
@return Array

@type function
/*/

User Function TRETP038()

	Local aRotAdic := {}
	Local aRotAdicPrcNeg := {}
	
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento

	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aRotAdic
	EndIf

//----------------------------------------------------------------------------------------------------------
// [n][1] - Nome da Funcionalidade
// [n][2] - Função de Usuário
// [n][3] - Operação (1-Pesquisa; 2-Visualização; 3-Inclusão; 4-Alteração; 5-Exclusão)
// [n][4] - Acesso relacionado a rotina, se esta posição não for informada nenhum acesso será validado
//----------------------------------------------------------------------------------------------------------

	if lTP_ACTLCS
		aAdd( aRotAdic, { "Limite Credito", "U_TRET052A"  , 0, 4 } ) //limites do cliente por segmento
	endif

	aAdd( aRotAdic, { "Negociação de Pagamento"	, "U_TRET022E(SA1->A1_COD,SA1->A1_LOJA)", 4, 0 } )	// Amarracao cliente x placas x motoristas

	//Montando submenu
	aAdd( aRotAdicPrcNeg, { "Negociação de Preços"	, "U_TRETA023(2)"						, 4, 0 } )	// Negociaçao de Preços
	aAdd( aRotAdicPrcNeg, { "Acompanhamento de Preços", "U_TRETA047(.T.)"						, 4, 0 } )	// Acompanhamento de Preços
	aAdd( aRotAdicPrcNeg, { "Histórico de Preços"		, "U_TRETA049(.T.)"						, 4, 0 } )	// Histórico de Preços
	aAdd( aRotAdic,	{ "Negociação de Preços",aRotAdicPrcNeg, 0 , 3})

	aAdd( aRotAdic, { "Cadastrar Recado"		, "U_TRETP38B()"						, 4, 0 } )	// Cadastro de recados para o cliente
	aAdd( aRotAdic, { "Pesquisa Placa"		    , "U_TRETP38A()"							, 1, 0 } )	// Pesquisa por placa
	//If FindFunction("U_TRETA050")
	//	aAdd( aRotAdic, { "Dados Complementares Consolidado", "U_TRETA050(SA1->A1_COD,'SA1')"       , 4, 0 } ) 	// Bloqueios e Limites de Créditos
	//EndIf

Return aRotAdic

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETP38A
 Função que posicona no cadastro de cliente pela placa informada

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETP38A()

	Local aPar		:= {}
	Local aRet		:= {}
	Local aCliByGrp := {}
	Local nPosCliGrp := 1

	aPar	:= {}
	aAdd(aPar, {1, "Placa:", Space(10),,,"DA3",,, .T.})

	If ParamBox(aPar, "Informe o número da placa", @aRet)

		//Projeto do Totvs PDV - utilizado a tabela DA3
		If DA3->(FieldPos("DA3_XCODCL")) > 0 .and. DA3->(FieldPos("DA3_XLOJCL")) > 0 .and. DA3->(FieldPos("DA3_XGRPCL")) > 0

			DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
			If DA3->(DbSeek(xFilial("DA3")+AllTrim(aRet[1])))

				If !Empty(DA3->DA3_XCODCL) //placa atribuida da um cliente/loja

					SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
					If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XCODCL+DA3->DA3_XLOJCL))
						//--- Verifica se ja existe a mBrowse e posiciona no registro encontrado...
						oBrowse1 := GetMBrowse()
						If Type("oBrowse1") <> "U"
							oBrowse1:GoTo( SA1->(Recno()) )
							oBrowse1:Refresh()
						EndIf
						MsgInfo("Cliente encontrado e posicionado!","Atenção")
					EndIf

				ElseIf !Empty(DA3->DA3_XGRPCL) //placa atribuida a um grupo

					SA1->(DbSetOrder(6)) //A1_FILIAL+A1_GRPVEN
					If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XGRPCL))
						While SA1->(!Eof()) .AND. SA1->A1_FILIAL+SA1->A1_GRPVEN == xFilial("SA1")+DA3->DA3_XGRPCL
							aadd(aCliByGrp, {SA1->A1_COD, SA1->A1_LOJA, SA1->A1_NOME, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CGC } )
							SA1->(DbSkip())
						EndDo
					EndIf

					If len(aCliByGrp) > 0
						aSort(aCliByGrp,,,{|x,y| x[1]+x[2] < y[1]+y[2]}) //ordem crescente: A1_COD + A1_LOJA
						If len(aCliByGrp) > 1
							//abrir tela para seleçao cliente
							nPosCliGrp := U_TPDVP08B(aCliByGrp, DA3->DA3_XGRPCL, DA3->DA3_PLACA, .F.)
						EndIf

						SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
						If SA1->(DbSeek(xFilial("SA1")+aCliByGrp[nPosCliGrp][1]+aCliByGrp[nPosCliGrp][2]))
							//--- Verifica se ja existe a mBrowse e posiciona no registro encontrado...
							oBrowse1 := GetMBrowse()
							If Type("oBrowse1") <> "U"
								oBrowse1:GoTo( SA1->(Recno()) )
								oBrowse1:Refresh()
							EndIf
							MsgInfo("Cliente encontrado e posicionado!","Atenção")
						EndIf
					EndIf

				Else
					If MsgYesno("Placa "+AllTrim(aRet[1])+" não tem amarração com cliente. Deseja incluir amarração agora?","Atenção")
						FWExecView('ALTERAR','OMSA060',4,,{|| .T. /*fecha janela no ok*/ }) //Alteração da rotina de Cadastro de Veículos (OMSA060)
					EndIf
				EndIf
			Else
				If MsgYesNo("Placa nao encontrada. Deseja cadastrar a placa agora?","Atenção")
					FWExecView('INCLUIR','OMSA060',3,,{|| .F. /*fecha janela no ok*/ })
				EndIf
			EndIf

		EndIf

	EndIf

Return

*/
//-------------------------------------------------------------------
/*/{Protheus.doc} TRETP38B
Funcao para Chamar a Tela de Cad Recados pelo acoes relacionadas da tela de clientes
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETP38B()
	Local lRet := .T.

	FWExecView('Inclusão de Recados','TRETA040', 3,, {|| .T. /*fecha janela no ok*/ })

Return(lRet)
