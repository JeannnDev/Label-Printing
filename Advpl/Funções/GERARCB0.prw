
/*--------------------------------------------------------------------------------*
 | Função : GERAPCB0                                                              |
 | Desc   : Inclui e já imprime etiqueta (Inclusão + Impressão)                   |
 | Autor  : Jean Correa da Silva                                                  |
 | Data   : 24/04/2026                                                            |
*--------------------------------------------------------------------------------*/


#Include "rwmake.ch"
#Include "protheus.ch"
#Include "topconn.ch"
#Include "totvs.ch"

User Function GERAPCB0(cFil, cOpc, cProd, cOrdProd, nQuant, cMultpla, cTipoImpressao, cLayoutT, cGetArm, cGetEnd, cIdImpres)

    Local aArea             := GetArea()
    Local cUsuario          := RetCodUsr()
    Local aRet              := {.F., ""}
    Local cCodEti           := ""
    Local lOk               := .T.
    Local i
    Local aEtiquetas        := {}
    Local oJson             := JsonObject():New()
    Local oRet              := JsonObject():New()
    Local aDados            := {}
    Local cUrl              := ""
    Local cChave            := ""
    Local cValor            := ""
    Local cIdLabel          := ""

    Default cOpc            := "I"
    Default nQuant          := 1
    Default cMultpla        := "U"
    Default cTipoImpressao  := "L"
    Default cIdImpres       := ""

    // Validação do Produto
    If !ValProd(cProd)
        RestArea(aArea)
        aRet[2] := "Produto " + cProd + " não localizado."
        Return aRet
    EndIf

    // Validação da Ordem de Produção
    If !ValOP(cOrdProd)
        RestArea(aArea)
        aRet[2] := "Ordem de Produção " + cOrdProd + " não localizada."
        Return aRet
    EndIf

    // Validação do Armazém
    If !ValArm(cGetArm)
        RestArea(aArea)
        aRet[2] := "Armazém " + cGetArm + " não localizado."
        Return aRet
    EndIf

    // Validação do Endereço
    If !ValEnd(cGetEnd, cGetArm)
        RestArea(aArea)
        aRet[2] := "Endereço " + cGetEnd + " não localizado."
        MsgAlert(aRet[2])
        Return aRet
    EndIf


    // ========================
    // Inclusão ou Inclusão + Impressão
    // ========================
    If cOpc $ "IP"

        cCodEti := GetSx8Num("CB0", "CB0_CODETI")

        RecLock("CB0", .T.)
        CB0->CB0_FILIAL := xFilial("CB0")
        CB0->CB0_CODETI := cCodEti
        CB0->CB0_DTNASC := dDatabase
        CB0->CB0_TIPO   := SB1->B1_TIPO
        CB0->CB0_CODPRO := cProd
        CB0->CB0_QTDE   := nQuant
        CB0->CB0_USUARI := cUsuario
        CB0->CB0_OP     := cOrdProd
        // CB0->CB0_NUMIMP := ""
        CB0->CB0_STATUS := "GERADA"
        CB0->CB0_LOCAL  := cGetArm
        CB0->CB0_LOCALI := cGetEnd
        CB0->CB0_LOTE   := ""
        CB0->CB0_FORNEC := ""
        CB0->CB0_LOJAFO := ""
        CB0->CB0_PEDCOM := ""
        CB0->CB0_NFENT  := ""
        CB0->CB0_SERIEE := ""
        CB0->CB0_CLI    := ""
        CB0->CB0_LOJACL := ""
        CB0->CB0_PEDVEN := ""
        CB0->CB0_NFSAI  := ""
        CB0->CB0_SERIES := ""
        // CB0->CB0_VOLUME := ""
        CB0->CB0_TRANSP := ""
        CB0->CB0_STATUS := ""
        CB0->CB0_ORIGEM := ""
        CB0->CB0_ITNFE  := ""
        // CB0->CB0_NUMIMP := ""
        MsUnlock()
        ConfirmSx8()

        //P - Incluir + Imprimir
        If cOpc == "P"

            If cTipoImpressao == "L"

                For i := 1 To nQuant
                    aAdd(aEtiquetas, cCodEti)
                Next i

                If Type("U_AESTR17") == "CF"
                    lOk := U_AESTR17( xFilial("SB1"), ;
                        SB1->B1_COD, ;
                        SB1->B1_DESC, ;
                        SB1->B1_TIPO, ;
                        dDatabase, ;
                        aEtiquetas, ;
                        SB1->B1_UM, ;
                        "" )
                Else
                    lOk := .F.

                EndIf

                If lOk

                    aRet[2] += " | " + AllTrim(Str(nQuant)) + " etiqueta(s) impressa(s) localmente."

                Else

                    aRet := {.F., "Falha na impressão local da etiqueta " + cCodEti}

                EndIf

            ElseIf cTipoImpressao == "R"

                aDados   =   U_GINT002(cLayoutT)[1]

                //1 - Pegar a Url Configurada na tabela de Parâmetros
                cUrl    :=   aDados[1]

                //2 - Montar o JSON com os dados da etiqueta

                For i := 1 To Len(aDados[4])

                    // 3 - Pegar a chave e o valor do parâmetro para acessar de forma dinâmica
                    cChave  :=   aDados[4][i][1]
                    cValor  :=   aDados[4][i][2]

                    // 4 - Fazer um If para a montagem do JSON
                    If Empty(cIdImpres) .AND. cChave == "printer"

                        cIdImpres := cValor

                    ElseIf cChave == "label"

                        cIdLabel := cValor

                    Else

                        oJson[cChave] := cValor

                    EndIf

                Next i

                If Empty(cIdImpres) .Or. Empty(cIdLabel)

                    aRet[2] := "Parâmetros de impressora ou etiqueta não informados."
                    RestArea(aArea)
                    Return lRet

                Endif

                oRet["printer"] := cIdImpres
                oRet["label"] := cIdLabel
                oRet["data"] := oJson


                For i := 1 To iiF(cMultpla=="U",1,nQuant)

                    U_WsRestPost(cUrl,"",oRet:ToJson(),"")

                Next i

                aRet[1] := .T.
                aRet[2] := "Etiqueta " + cCodEti + " enviada para impressão

            EndIf

        EndIf

    EndIf

    RestArea(aArea)
Return aRet


/**********************************************************************************************************************************/
/** Static Function ValProd()                                                                                                    **/
/** Valida o Produto                                                                                                             **/
/**********************************************************************************************************************************/
Static Function ValProd(cProdx)
    Local aArea := GetArea()
    Local nTamCampo := TamSX3("B1_COD")[1]
    Local cProdxFmt := PadR(cProdx, nTamCampo)
    Local lRet  := .F.
    Local cSeek := xFilial("SB1") + AllTrim(cProdx)


    If Empty(cProdx)
        MsgAlert("Produto não informado.")
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("SB1")
    SB1->(DbSetOrder(1))

    If !SB1->(DbSeek(cSeek))
        MsgAlert("Produto " + cProdx + " não encontrado.")
        RestArea(aArea)
        Return lRet
    EndIf

    If !SB1->B1_COD == cProdxFmt
        MsgAlert("Codigo Invalido do Produto")
        RestArea(aArea)
        Return lRet
    EndIf

    RestArea(aArea)
    lRet := .T.
Return lRet



/**********************************************************************************************************************************/
/** Static Function ValOP(cOP)                                                                                                   **/
/** Valida a Ordem de Produção                                                                                                   **/
/**********************************************************************************************************************************/
Static Function ValOP(cOPz)
    Local aArea     := GetArea()
    Local nTamCampo := TamSX3("C2_OP")[1]
    Local cOPFmt    := PadR(cOPz, nTamCampo)
    Local cSeek     := xFilial("SC2") + cOPFmt
    Local lRet      := .F.

    If Empty(cOPz)
        MsgAlert("Ordem de Produção não informada.")
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("SC2")
    SC2->(DbSetOrder(1))

    If !SC2->(DbSeek(cSeek))
        MsgAlert("A Ordem de Produção " + cOPz + " não foi localizada.")
        RestArea(aArea)
        Return lRet
    EndIf

    If !SC2->C2_OP == cOPFmt
        MsgAlert("Codigo Invalido da OP")
        RestArea(aArea)
        Return lRet
    EndIf

    RestArea(aArea)
    lRet := .T.
Return lRet


/**********************************************************************************************************************************/
/** Static Function ValArm()                                                                                                     **/
/** Valida o Armazém                                                                                                             **/
/**********************************************************************************************************************************/
Static Function ValArm(cArmz)
    Local aArea     := GetArea()
    Local nTamCampo := TamSX3("NNR_CODIGO")[1]
    Local cArmFmt   := PadR(cArmz, nTamCampo)
    Local cSeek     := xFilial("NNR") + cArmFmt
    Local lRet      := .F.

    If Empty(cArmz)
        MsgAlert("Armazém não informado.")
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("NNR")
    NNR->(DbSetOrder(1))

    If !NNR->(DbSeek(cSeek))
        MsgAlert("O Armazém " + cArmz + " não foi localizado.")
        RestArea(aArea)
        Return lRet
    EndIf

    If !NNR->NNR_CODIGO == cArmFmt
        MsgAlert("Código inválido do Armazém.")
        RestArea(aArea)
        Return lRet
    EndIf

    RestArea(aArea)
    lRet := .T.
Return lRet

/**********************************************************************************************************************************/
/** Static Function ValEnd()                                                                                                     **/
/** Valida o Endereço                                                                                                            **/
/**********************************************************************************************************************************/
Static Function ValEnd(cEndz, cArmz)

    Local aArea        := GetArea()
    Local nTamArm      := TamSX3("NNR_CODIGO")[1]
    Local nTamEnd      := TamSX3("BE_LOCALIZ")[1]
    Local cArmFmt      := PadR(AllTrim(cArmz), nTamArm)
    Local cEndFmt      := PadR(AllTrim(cEndz), nTamEnd)
    Local cSeek        := xFilial("SBE") + cArmFmt + cEndFmt
    Local lRet         := .F.

    If Empty(cArmz)
        MsgAlert("Armazém não informado.")
        RestArea(aArea)
        Return lRet
    EndIf

    If Empty(cEndz)
        RestArea(aArea)
        Return .T.
    EndIf

    DbSelectArea("SBE")
    SBE->(DbSetOrder(1))

    If !SBE->(DbSeek(cSeek))
        MsgAlert("O endereço " + cEndz + " não foi localizado no armazém " + cArmz + ".")
        RestArea(aArea)
        Return lRet
    EndIf

    If !NNR->NNR_CODIGO == cArmz
        MsgAlert("O endereço informado não pertence ao armazém " + AllTrim(cArmz) + ".")
        RestArea(aArea)
        Return lRet
    EndIf

    RestArea(aArea)
    lRet := .T.
Return lRet
